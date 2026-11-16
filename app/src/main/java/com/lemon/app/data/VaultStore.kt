package com.lemon.app.data

import android.content.Context
import android.content.SharedPreferences
import com.lemon.app.security.CryptoManager
import org.json.JSONObject
import java.io.File

/**
 * Holds the unlocked vault in memory and persists it as an encrypted file.
 * Three profiles exist: REAL (your PIN), SECRET (secret PIN, polished decoy)
 * and PSEUDO (any wrong PIN, obvious decoy).
 */
object VaultStore {

    enum class Profile { REAL, PSEUDO, SECRET }

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

    val entries = ArrayList<VaultEntry>()
    val totps = ArrayList<TotpEntry>()

    fun init(context: Context) {
        if (::appContext.isInitialized) return
        appContext = context.applicationContext
        prefs = appContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    }

    fun isSetupDone(): Boolean = prefs?.getBoolean(KEY_SETUP_DONE, false) ?: false

    fun markSetupDone() {
        prefs?.edit()?.putBoolean(KEY_SETUP_DONE, true)?.apply()
    }

    private fun fileFor(profile: Profile): File =
        File(appContext.filesDir, profile.name.lowercase() + ".vault")

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
            ?.apply()
    }

    fun tryUnlock(profile: Profile, pin: String): Boolean {
        val p = prefs ?: return false
        val saltB64 = p.getString(saltKey(profile), null) ?: return false
        val verifier = p.getString(verifierKey(profile), null) ?: return false
        val key = CryptoManager.deriveKey(pin, CryptoManager.unb64(saltB64))
        if (!CryptoManager.checkVerifier(key, verifier)) return false
        unlockWith(profile, key)
        return true
    }

    /** Pseudo profile: no PIN check at all - any wrong PIN opens this decoy. */
    fun unlockPseudo(): Boolean {
        val p = prefs ?: return false
        val saltB64 = p.getString(saltKey(Profile.PSEUDO), null)
        val salt = if (saltB64 != null) CryptoManager.unb64(saltB64) else CryptoManager.randomBytes(16)
        val key = CryptoManager.deriveKey(PSEUDO_PIN, salt)
        unlockWith(Profile.PSEUDO, key)
        return true
    }

    private fun unlockWith(profile: Profile, key: ByteArray) {
        this.profile = profile
        this.masterKey = key
        load()
        unlocked = true
    }

    fun lock() {
        masterKey?.fill(0)
        masterKey = null
        unlocked = false
        entries.clear()
        totps.clear()
    }

    fun wipeAll() {
        Profile.values().forEach { fileFor(it).delete() }
        prefs?.edit()?.clear()?.apply()
        lock()
    }

    fun addEntry(entry: VaultEntry) {
        entries.add(entry)
        persist()
    }

    fun updateEntry(entry: VaultEntry) {
        val i = entries.indexOfFirst { it.id == entry.id }
        if (i >= 0) entries[i] = entry
        persist()
    }

    fun deleteEntry(id: String) {
        entries.removeAll { it.id == id }
        persist()
    }

    fun addTotp(entry: TotpEntry) {
        totps.add(entry)
        persist()
    }

    fun updateTotp(entry: TotpEntry) {
        val i = totps.indexOfFirst { it.id == entry.id }
        if (i >= 0) totps[i] = entry
        persist()
    }

    fun deleteTotp(id: String) {
        totps.removeAll { it.id == id }
        persist()
    }

    private fun persist() {
        val key = masterKey ?: return
        val json = JSONObject().apply {
            put("entries", VaultJson.entriesToJson(entries))
            put("totps", VaultJson.totpsToJson(totps))
        }.toString()
        fileFor(profile).writeBytes(CryptoManager.encrypt(key, json.toByteArray()))
    }

    private fun load() {
        val key = masterKey ?: return
        val file = fileFor(profile)
        if (!file.exists()) {
            seedIfEmpty()
            return
        }
        val plain = CryptoManager.decrypt(key, file.readBytes())
        if (plain == null) {
            seedIfEmpty()
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
        }
    }

    private fun seedIfEmpty() {
        when (profile) {
            Profile.PSEUDO -> SeedData.pseudo(entries, totps)
            Profile.SECRET -> SeedData.secret(entries, totps)
            Profile.REAL -> {
                entries.clear()
                totps.clear()
            }
        }
        persist()
    }
}
