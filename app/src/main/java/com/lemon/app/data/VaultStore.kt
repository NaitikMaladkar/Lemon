package com.lemon.app.data

import android.content.Context
import android.content.SharedPreferences
import com.lemon.app.security.CryptoManager
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream

/**
 * Holds the unlocked vault in memory and persists it as an encrypted file.
 * Two profiles exist: REAL (your 4-digit PIN) and PSEUDO (any wrong PIN).
 *
 * Persistence is crash safe:
 *  - every save is written to a temp file, fsynced, then atomically renamed
 *  - the previous good file is kept as a ".bak" backup and is used
 *    automatically if the main file is ever unreadable
 *  - nothing is ever overwritten while the vault is locked or read-only
 */
object VaultStore {

    enum class Profile { REAL, PSEUDO }

    private const val PREFS = "lemon_prefs"
    private const val KEY_SETUP_DONE = "setup_done"
    private const val KEY_SALT = "salt_%s"
    private const val KEY_VERIFIER = "verifier_%s"
    private const val PSEUDO_PIN = "pseudo-decoy"

    private lateinit var appContext: Context
    private var prefs: SharedPreferences? = null

    var profile: Profile = Profile.REAL
        private set
    var masterKey: ByteArray? = null
        private set
    var unlocked: Boolean = false
        private set

    /** True when no vault could be read at all - blocks writes so data is never overwritten. */
    var readOnly: Boolean = false
        private set

    val entries = ArrayList<VaultEntry>()
    val totps = ArrayList<TotpEntry>()

    fun init(context: Context) {
        if (::appContext.isInitialized) return
        appContext = context.applicationContext
        prefs = appContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    }

    fun isSetupDone(): Boolean = prefs?.getBoolean(KEY_SETUP_DONE, false) ?: false

    fun markSetupDone() {
        // commit() (not apply()) so the flag survives an immediate process kill
        prefs?.edit()?.putBoolean(KEY_SETUP_DONE, true)?.commit()
    }

    private fun vaultFile(p: Profile): File =
        File(appContext.filesDir, p.name.lowercase() + ".vault")

    private fun backupFile(p: Profile): File =
        File(appContext.filesDir, p.name.lowercase() + ".vault.bak")

    private fun tempFile(p: Profile): File =
        File(appContext.filesDir, p.name.lowercase() + ".vault.tmp")

    private fun saltKey(p: Profile) = String.format(KEY_SALT, p.name)
    private fun verifierKey(p: Profile) = String.format(KEY_VERIFIER, p.name)

    fun hasPin(profile: Profile): Boolean =
        !prefs?.getString(verifierKey(profile), null).isNullOrEmpty()

    fun createProfile(profile: Profile, pin: String) {
        val salt = CryptoManager.randomBytes(16)
        val key = CryptoManager.deriveKey(pin, salt)
        prefs?.edit()
            ?.putString(saltKey(profile), CryptoManager.b64(salt))
            ?.putString(verifierKey(profile), CryptoManager.makeVerifier(key))
            ?.commit()
    }

    fun tryUnlock(profile: Profile, pin: String): Boolean {
        val p = prefs ?: return false
        val saltB64 = p.getString(saltKey(profile), null) ?: return false
        val verifier = p.getString(verifierKey(profile), null) ?: return false
        val salt = try {
            CryptoManager.unb64(saltB64)
        } catch (e: Exception) {
            return false
        }
        val key = CryptoManager.deriveKey(pin, salt)
        if (!CryptoManager.checkVerifier(key, verifier)) return false
        unlockWith(profile, key)
        return true
    }

    /** Pseudo profile: no PIN check at all - any wrong PIN opens this decoy. */
    fun unlockPseudo(): Boolean {
        val p = prefs ?: return false
        val saltB64 = p.getString(saltKey(Profile.PSEUDO), null)
        val salt = if (saltB64 != null) {
            try {
                CryptoManager.unb64(saltB64)
            } catch (e: Exception) {
                CryptoManager.randomBytes(16)
            }
        } else {
            val newSalt = CryptoManager.randomBytes(16)
            p.edit().putString(saltKey(Profile.PSEUDO), CryptoManager.b64(newSalt)).commit()
            newSalt
        }
        val key = CryptoManager.deriveKey(PSEUDO_PIN, salt)
        unlockWith(Profile.PSEUDO, key)
        return true
    }

    /**
     * Re-encrypts the vault with a new PIN.
     *
     * The REAL vault is re-keyed only when the current PIN checks out. Inside
     * the decoy vault the decoy file is re-keyed instead - previously this
     * wrote a new key over the REAL salt/verifier while the real file was
     * still encrypted with the old key, which made the real vault unreadable.
     */
    fun changePin(currentPin: String, newPin: String): Boolean {
        val p = prefs ?: return false
        if (readOnly) return false
        if (profile != Profile.REAL) return rekeyCurrent(newPin)
        val saltB64 = p.getString(saltKey(Profile.REAL), null) ?: return false
        val verifier = p.getString(verifierKey(Profile.REAL), null) ?: return false
        val salt = try {
            CryptoManager.unb64(saltB64)
        } catch (e: Exception) {
            return false
        }
        val oldKey = CryptoManager.deriveKey(currentPin, salt)
        if (!CryptoManager.checkVerifier(oldKey, verifier)) return false

        val newSalt = CryptoManager.randomBytes(16)
        val newKey = CryptoManager.deriveKey(newPin, newSalt)
        masterKey = newKey
        val written = persist()
        if (!written) {
            // roll back so the in-memory key never drifts from the on-disk one
            masterKey = oldKey
            return false
        }
        p.edit()
            .putString(saltKey(Profile.REAL), CryptoManager.b64(newSalt))
            .putString(verifierKey(Profile.REAL), CryptoManager.makeVerifier(newKey))
            .commit()
        return true
    }

    /** Re-encrypts whichever vault is currently open with a fresh salt + key. */
    private fun rekeyCurrent(newPin: String): Boolean {
        val p = prefs ?: return false
        val oldKey = masterKey ?: return false
        val newSalt = CryptoManager.randomBytes(16)
        val newKey = CryptoManager.deriveKey(newPin, newSalt)
        masterKey = newKey
        if (!persist()) {
            masterKey = oldKey
            return false
        }
        p.edit()
            .putString(saltKey(profile), CryptoManager.b64(newSalt))
            .putString(verifierKey(profile), CryptoManager.makeVerifier(newKey))
            .commit()
        return true
    }

    private fun unlockWith(profile: Profile, key: ByteArray) {
        this.profile = profile
        this.masterKey = key
        readOnly = false
        load()
        unlocked = true
    }

    fun lock() {
        masterKey?.fill(0)
        masterKey = null
        unlocked = false
        readOnly = false
        entries.clear()
        totps.clear()
    }

    fun wipeAll() {
        Profile.values().forEach {
            vaultFile(it).delete()
            backupFile(it).delete()
            tempFile(it).delete()
        }
        prefs?.edit()?.clear()?.commit()
        lock()
    }

    fun addEntry(entry: VaultEntry): Boolean {
        entries.add(entry)
        return persist()
    }

    fun updateEntry(entry: VaultEntry): Boolean {
        val i = entries.indexOfFirst { it.id == entry.id }
        if (i >= 0) entries[i] = entry
        return persist()
    }

    fun deleteEntry(id: String): Boolean {
        entries.removeAll { it.id == id }
        return persist()
    }

    fun addTotp(entry: TotpEntry): Boolean {
        totps.add(entry)
        return persist()
    }

    fun updateTotp(entry: TotpEntry): Boolean {
        val i = totps.indexOfFirst { it.id == entry.id }
        if (i >= 0) totps[i] = entry
        return persist()
    }

    fun deleteTotp(id: String): Boolean {
        totps.removeAll { it.id == id }
        return persist()
    }

    /**
     * Crash-safe save: encrypt -> temp file -> fsync -> rotate the old file to
     * ".bak" -> atomic rename. A kill at any point leaves a readable vault.
     */
    private fun persist(): Boolean {
        val key = masterKey ?: return false
        if (readOnly) return false // never overwrite a vault we failed to read
        val target = vaultFile(profile)
        val bak = backupFile(profile)
        val tmp = tempFile(profile)
        return try {
            val json = JSONObject().apply {
                put("entries", VaultJson.entriesToJson(entries))
                put("totps", VaultJson.totpsToJson(totps))
            }.toString()
            val data = CryptoManager.encrypt(key, json.toByteArray())
            FileOutputStream(tmp).use { out ->
                out.write(data)
                out.flush()
                out.fd.sync()
            }
            if (target.exists()) {
                bak.delete()
                target.renameTo(bak)
            }
            if (!tmp.renameTo(target)) {
                tmp.copyTo(target, overwrite = true)
                tmp.delete()
            }
            true
        } catch (e: Exception) {
            tmp.delete()
            false
        }
    }

    private fun load() {
        val key = masterKey ?: return
        val main = vaultFile(profile)
        val bak = backupFile(profile)

        if (!main.exists() && !bak.exists()) {
            seedIfEmpty()
            return
        }

        // main file first, then the automatic backup
        var usedBackup = false
        var plain: ByteArray? = null
        if (main.exists()) plain = CryptoManager.decrypt(key, main.readBytes())
        if (plain == null && bak.exists()) {
            plain = CryptoManager.decrypt(key, bak.readBytes())
            usedBackup = plain != null
        }
        if (plain == null) {
            // Nothing decrypted. Keep the files intact and show an empty vault
            // instead of silently destroying the data.
            entries.clear()
            totps.clear()
            readOnly = true
            return
        }

        try {
            val obj = JSONObject(String(plain))
            entries.clear()
            entries.addAll(VaultJson.entriesFromJson(obj.optString("entries", "[]")))
            totps.clear()
            totps.addAll(VaultJson.totpsFromJson(obj.optString("totps", "[]")))
        } catch (e: Exception) {
            entries.clear()
            totps.clear()
            readOnly = true
            return
        }

        // Heal the main file if we had to fall back to the backup.
        if (usedBackup) persist()
    }

    private fun seedIfEmpty() {
        when (profile) {
            Profile.PSEUDO -> SeedData.pseudo(entries, totps)
            Profile.REAL -> {
                entries.clear()
                totps.clear()
            }
        }
        persist()
    }
}
