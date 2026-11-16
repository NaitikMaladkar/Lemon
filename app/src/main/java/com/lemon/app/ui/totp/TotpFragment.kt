package com.lemon.app.ui.totp

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.widget.TextView
import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.google.android.material.floatingactionbutton.FloatingActionButton
import com.lemon.app.R
import com.lemon.app.data.TotpEntry
import com.lemon.app.data.VaultStore
import com.lemon.app.ui.AddEditActivity
import com.lemon.app.ui.AddTotpActivity
import com.lemon.app.ui.ScannerActivity

class TotpFragment : Fragment(R.layout.fragment_totp) {

    private lateinit var adapter: TotpAdapter
    private var recyclerView: RecyclerView? = null
    private val handler = Handler(Looper.getMainLooper())
    private val ticker = object : Runnable {
        override fun run() {
            tickVisibleCodes()
            handler.postDelayed(this, 1000)
        }
    }

    /** Refresh codes in place so rows don't rebind (keeps popups/scroll stable). */
    private fun tickVisibleCodes() {
        val rv = recyclerView ?: return
        for (i in 0 until rv.childCount) {
            (rv.getChildViewHolder(rv.getChildAt(i)) as? TotpAdapter.VH)?.refreshCode()
        }
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val emptyView = view.findViewById<TextView>(R.id.empty_view)
        val list = view.findViewById<RecyclerView>(R.id.totp_list)
        recyclerView = list
        list.layoutManager = LinearLayoutManager(requireContext())

        adapter = TotpAdapter(
            onCopy = { entry ->
                val code = com.lemon.app.totp.Totp.code(
                    entry.secret,
                    period = entry.period,
                    digits = entry.digits,
                    algorithm = entry.algorithm
                )
                AddEditActivity.copyToClipboard(requireContext(), code)
                Toast.makeText(requireContext(), R.string.copied, Toast.LENGTH_SHORT).show()
            },
            onDelete = { entry ->
                MaterialAlertDialogBuilder(requireContext())
                    .setTitle(R.string.delete)
                    .setMessage(R.string.delete_confirm)
                    .setNegativeButton(R.string.cancel, null)
                    .setPositiveButton(R.string.delete) { _, _ ->
                        VaultStore.deleteTotp(entry.id)
                        reload()
                    }
                    .show()
            }
        )
        list.adapter = adapter

        view.findViewById<FloatingActionButton>(R.id.fab_add_totp).setOnClickListener {
            MaterialAlertDialogBuilder(requireContext())
                .setTitle(R.string.totp_add)
                .setItems(arrayOf(getString(R.string.totp_scan), getString(R.string.totp_manual))) { _, which ->
                    if (which == 0) {
                        startActivity(Intent(requireContext(), ScannerActivity::class.java))
                    } else {
                        startActivity(Intent(requireContext(), AddTotpActivity::class.java))
                    }
                }
                .show()
        }
    }

    override fun onResume() {
        super.onResume()
        reload()
        handler.postDelayed(ticker, 1000)
    }

    override fun onPause() {
        super.onPause()
        handler.removeCallbacks(ticker)
    }

    private fun reload() {
        adapter.submit(VaultStore.totps)
        view?.findViewById<TextView>(R.id.empty_view)?.visibility =
            if (VaultStore.totps.isEmpty()) View.VISIBLE else View.GONE
    }
}
