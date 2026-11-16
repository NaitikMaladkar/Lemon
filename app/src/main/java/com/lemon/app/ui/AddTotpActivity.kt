package com.lemon.app.ui

import android.os.Bundle
import android.widget.Button
import android.widget.Toast
import com.google.android.material.textfield.TextInputEditText
import com.lemon.app.R
import com.lemon.app.data.TotpEntry
import com.lemon.app.data.VaultStore
import com.lemon.app.totp.Totp
import com.lemon.app.util.SecureActivity

/** Manual TOTP entry (label, issuer, Base32 secret). Also used for editing. */
class AddTotpActivity : SecureActivity() {

    private var editingId: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_add_totp)

        editingId = intent.getStringExtra(EXTRA_ID)
        val label = findViewById<TextInputEditText>(R.id.input_totp_label)
        val issuer = findViewById<TextInputEditText>(R.id.input_totp_issuer)
        val secret = findViewById<TextInputEditText>(R.id.input_totp_secret)
        val save = findViewById<Button>(R.id.button_add_totp)

        val existing = editingId?.let { id -> VaultStore.totps.firstOrNull { it.id == id } }
        if (existing != null) {
            label.setText(existing.label)
            issuer.setText(existing.issuer)
            secret.setText(existing.secret)
            save.text = getString(R.string.save)
        }

        save.setOnClickListener {
            val l = label.text?.toString()?.trim().orEmpty()
            val s = secret.text?.toString()?.trim().orEmpty()
            if (l.isEmpty()) {
                label.error = getString(R.string.name_required)
                return@setOnClickListener
            }
            if (!Totp.isValidBase32(s)) {
                secret.error = getString(R.string.totp_invalid_secret)
                return@setOnClickListener
            }
            val i = issuer.text?.toString()?.trim().orEmpty()
            val saved = if (existing != null) {
                existing.label = l
                existing.issuer = i
                existing.secret = s.uppercase()
                VaultStore.updateTotp(existing)
            } else {
                VaultStore.addTotp(TotpEntry(label = l, issuer = i, secret = s.uppercase()))
            }
            if (!saved) {
                Toast.makeText(this, R.string.vault_readonly, Toast.LENGTH_LONG).show()
                return@setOnClickListener
            }
            Toast.makeText(this, R.string.saved, Toast.LENGTH_SHORT).show()
            finish()
        }
    }

    companion object {
        const val EXTRA_ID = "totp_id"
    }
}
