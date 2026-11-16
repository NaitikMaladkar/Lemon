package com.lemon.app.ui

import android.content.Intent
import android.os.Bundle
import android.view.MenuItem
import com.google.android.material.appbar.MaterialToolbar
import com.google.android.material.bottomnavigation.BottomNavigationView
import com.lemon.app.R
import com.lemon.app.data.VaultStore
import com.lemon.app.ui.generator.GeneratorFragment
import com.lemon.app.ui.passwords.PasswordsFragment
import com.lemon.app.ui.totp.TotpFragment
import com.lemon.app.util.SecureActivity

class MainActivity : SecureActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (!VaultStore.unlocked) {
            startActivity(Intent(this, PinActivity::class.java))
            finish()
            return
        }

        setContentView(R.layout.activity_main)

        val toolbar = findViewById<MaterialToolbar>(R.id.toolbar)
        toolbar.inflateMenu(R.menu.menu_main)
        toolbar.setOnMenuItemClickListener { item -> onMenu(item) }

        val nav = findViewById<BottomNavigationView>(R.id.bottom_nav)
        nav.setOnItemSelectedListener { item ->
            when (item.itemId) {
                R.id.nav_passwords -> show(PasswordsFragment())
                R.id.nav_generator -> show(GeneratorFragment())
                R.id.nav_totp -> show(TotpFragment())
            }
            true
        }

        if (savedInstanceState == null) {
            nav.selectedItemId = R.id.nav_passwords
        }
    }

    private fun show(fragment: androidx.fragment.app.Fragment) {
        supportFragmentManager.beginTransaction()
            .replace(R.id.fragment_container, fragment)
            .commit()
    }

    private fun onMenu(item: MenuItem): Boolean {
        return when (item.itemId) {
            R.id.action_settings -> {
                startActivity(Intent(this, SettingsActivity::class.java))
                true
            }
            R.id.action_lock -> {
                lockNow()
                true
            }
            else -> false
        }
    }

    private fun lockNow() {
        VaultStore.lock()
        val intent = Intent(this, PinActivity::class.java)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        startActivity(intent)
        finish()
    }
}
