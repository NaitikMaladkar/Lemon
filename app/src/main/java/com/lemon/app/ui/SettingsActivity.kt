package com.lemon.app.ui

import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.RadioGroup
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatDelegate
import androidx.appcompat.widget.Toolbar
import com.google.android.material.textfield.TextInputEditText
import com.lemon.app.R
import com.lemon.app.data.AppPrefs
import com.lemon.app.data.VaultStore
import com.lemon.app.util.SecureActivity

/**
 * Settings: appearance, change PIN, lock now, erase all data.
 */
class SettingsActivity : SecureActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_settings)

        val toolbar = findViewById<Toolbar>(R.id.toolbar)
        setSupportActionBar(toolbar)
        toolbar.setNavigationOnClickListener { finish() }

        try {
            val version = packageManager.getPackageInfo(packageName, 0).versionName ?: "1.0"
            findViewById<TextView>(R.id.text_version).text =
                getString(R.string.settings_version, version)
        } catch (e: Exception) {
            // ignore
        }

        val group = findViewById<RadioGroup>(R.id.theme_group)
        when (AppPrefs.getThemeMode(this)) {
            AppPrefs.THEME_LIGHT -> group.check(R.id.theme_light)
            AppPrefs.THEME_DARK -> group.check(R.id.theme_dark)
            else -> group.check(R.id.theme_system)
        }
        group.setOnCheckedChangeListener { _, checkedId ->
            val mode = when (checkedId) {
                R.id.theme_light -> AppPrefs.THEME_LIGHT
                R.id.theme_dark -> AppPrefs.THEME_DARK
                else -> AppPrefs.THEME_SYSTEM
            }
            AppPrefs.setThemeMode(this, mode)
            AppCompatDelegate.setDefaultNightMode(
                when (mode) {
                    AppPrefs.THEME_LIGHT -> AppCompatDelegate.MODE_NIGHT_NO
                    AppPrefs.THEME_DARK -> AppCompatDelegate.MODE_NIGHT_YES
                    else -> AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM
                }
            )
        }

        findViewById<Button>(R.id.button_change_pin).setOnClickListener { showChangePin() }
        findViewById<Button>(R.id.button_lock_now).setOnClickListener {
            VaultStore.lock()
            startActivity(Intent(this, PinActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            })
            finish()
        }
        findViewById<Button>(R.id.button_wipe).setOnClickListener { confirmWipe() }
    }

    private fun showChangePin() {
        val view = layoutInflater.inflate(R.layout.dialog_change_pin, null)
        val current = view.findViewById<TextInputEditText>(R.id.input_current)
        val newPin = view.findViewById<TextInputEditText>(R.id.input_new)
        val confirm = view.findViewById<TextInputEditText>(R.id.input_confirm)
        val dialog = AlertDialog.Builder(this)
            .setTitle(R.string.change_pin_title)
            .setView(view)
            .setPositiveButton(R.string.save, null)
            .setNegativeButton(R.string.cancel, null)
            .create()
        dialog.show()
        dialog.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener {
            val c = current.text?.toString()?.trim().orEmpty()
            val n = newPin.text?.toString()?.trim().orEmpty()
            val cf = confirm.text?.toString()?.trim().orEmpty()
            if (n.length != 4 || !n.all { it.isDigit() }) {
                newPin.error = getString(R.string.pin_not_4)
                return@setOnClickListener
            }
            if (n != cf) {
                confirm.error = getString(R.string.change_pin_mismatch)
                return@setOnClickListener
            }
            if (VaultStore.changePin(c, n)) {
                Toast.makeText(this, R.string.change_pin_done, Toast.LENGTH_SHORT).show()
                dialog.dismiss()
            } else {
                current.error = getString(R.string.change_pin_wrong)
            }
        }
    }

    private fun confirmWipe() {
        AlertDialog.Builder(this)
            .setTitle(R.string.settings_wipe)
            .setMessage(R.string.settings_wipe_confirm)
            .setPositiveButton(R.string.settings_wipe) { _, _ ->
                VaultStore.wipeAll()
                startActivity(Intent(this, SetupActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                })
                finish()
            }
            .setNegativeButton(R.string.cancel, null)
            .show()
    }
}
