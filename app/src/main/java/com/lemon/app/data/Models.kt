package com.lemon.app.data

import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

data class VaultEntry(
    val id: String = UUID.randomUUID().toString(),
    var title: String,
    var username: String = "",
    var secret: String,
    var notes: String = "",
    var type: String = TYPE_PASSWORD,
    val createdAt: Long = System.currentTimeMillis(),
    var updatedAt: Long = System.currentTimeMillis()
) {
    companion object {
        const val TYPE_PASSWORD = "password"
        const val TYPE_PASSPHRASE = "passphrase"

        fun fromJson(o: JSONObject) = VaultEntry(
            id = o.optString("id", UUID.randomUUID().toString()),
            title = o.optString("title"),
            username = o.optString("username"),
            secret = o.optString("secret"),
            notes = o.optString("notes"),
            type = o.optString("type", TYPE_PASSWORD),
            createdAt = o.optLong("createdAt"),
            updatedAt = o.optLong("updatedAt")
        )
    }

    fun toJson() = JSONObject().apply {
        put("id", id)
        put("title", title)
        put("username", username)
        put("secret", secret)
        put("notes", notes)
        put("type", type)
        put("createdAt", createdAt)
        put("updatedAt", updatedAt)
    }
}

data class TotpEntry(
    val id: String = UUID.randomUUID().toString(),
    var label: String,
    var issuer: String = "",
    var secret: String,
    var period: Int = 30,
    var digits: Int = 6,
    var algorithm: String = "SHA1"
) {
    companion object {
        fun fromJson(o: JSONObject) = TotpEntry(
            id = o.optString("id", UUID.randomUUID().toString()),
            label = o.optString("label"),
            issuer = o.optString("issuer"),
            secret = o.optString("secret"),
            period = o.optInt("period", 30),
            digits = o.optInt("digits", 6),
            algorithm = o.optString("algorithm", "SHA1")
        )
    }

    fun toJson() = JSONObject().apply {
        put("id", id)
        put("label", label)
        put("issuer", issuer)
        put("secret", secret)
        put("period", period)
        put("digits", digits)
        put("algorithm", algorithm)
    }
}

object VaultJson {
    fun entriesToJson(list: List<VaultEntry>): String {
        val arr = JSONArray()
        list.forEach { arr.put(it.toJson()) }
        return arr.toString()
    }

    fun entriesFromJson(text: String): List<VaultEntry> {
        val arr = JSONArray(text)
        val out = ArrayList<VaultEntry>(arr.length())
        for (i in 0 until arr.length()) out.add(VaultEntry.fromJson(arr.getJSONObject(i)))
        return out
    }

    fun totpsToJson(list: List<TotpEntry>): String {
        val arr = JSONArray()
        list.forEach { arr.put(it.toJson()) }
        return arr.toString()
    }

    fun totpsFromJson(text: String): List<TotpEntry> {
        val arr = JSONArray(text)
        val out = ArrayList<TotpEntry>(arr.length())
        for (i in 0 until arr.length()) out.add(TotpEntry.fromJson(arr.getJSONObject(i)))
        return out
    }
}
