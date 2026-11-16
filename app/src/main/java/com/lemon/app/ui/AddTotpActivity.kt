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

class AddTotpActivity : SecureActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_add_totp)

        val label = findViewById<TextInputEditText>(R.id.input_totp_label)
        val issuer = findViewById<TextInputEditText>(R.id.input_totp_issuer)
        val secret = findViewById<TextInputEditText>(R.id.input_totp_secret)

        findViewById<Button>(R.id.button_add_totp).setOnClickListener {
            val secretText = secret.text?.toString()?.trim().orEmpty()
            if (!Totp.isValidBase32(secretText)) {
                Toast.makeText(this, R.string.totp_invalid_secret, Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            val labelText = label.text?.toString()?.trim().orEmpty().ifEmpty { "Account" }
            val issuerText = issuer.text?.toString()?.trim().orEmpty()
            VaultStore.addTotp(
                TotpEntry(
                    label = labelText,
                    issuer = issuerText,
                    secret = secretText.replace(" ", "").uppercase()
                )
            )
            Toast.makeText(this, R.string.totp_added, Toast.LENGTH_SHORT).show()
            finish()
        }
    }
}
