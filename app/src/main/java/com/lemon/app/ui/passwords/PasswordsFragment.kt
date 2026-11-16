package com.lemon.app.ui.passwords

import android.content.Intent
import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.view.View
import android.widget.TextView
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.floatingactionbutton.FloatingActionButton
import com.google.android.material.textfield.TextInputEditText
import com.lemon.app.R
import com.lemon.app.data.VaultEntry
import com.lemon.app.data.VaultStore
import com.lemon.app.ui.AddEditActivity

class PasswordsFragment : Fragment(R.layout.fragment_passwords) {

    private lateinit var adapter: EntryAdapter
    private lateinit var emptyView: TextView

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        emptyView = view.findViewById(R.id.empty_view)
        val list = view.findViewById<RecyclerView>(R.id.entries_list)
        list.layoutManager = LinearLayoutManager(requireContext())

        adapter = EntryAdapter(
            onEdit = { entry ->
                val i = Intent(requireContext(), AddEditActivity::class.java)
                i.putExtra(AddEditActivity.EXTRA_ID, entry.id)
                startActivity(i)
            },
            onDelete = { entry ->
                androidx.appcompat.app.AlertDialog.Builder(requireContext())
                    .setTitle(R.string.delete)
                    .setMessage(R.string.delete_confirm)
                    .setNegativeButton(R.string.cancel, null)
                    .setPositiveButton(R.string.delete) { _, _ ->
                        VaultStore.deleteEntry(entry.id)
                        reload()
                    }
                    .show()
            },
            onCopySecret = { entry ->
                AddEditActivity.copyToClipboard(requireContext(), entry.secret)
                android.widget.Toast.makeText(requireContext(), R.string.copied, android.widget.Toast.LENGTH_SHORT).show()
            },
            onCopyUsername = { entry ->
                AddEditActivity.copyToClipboard(requireContext(), entry.username)
                android.widget.Toast.makeText(requireContext(), R.string.copied, android.widget.Toast.LENGTH_SHORT).show()
            }
        )
        list.adapter = adapter

        view.findViewById<TextInputEditText>(R.id.search_input).addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, a: Int, b: Int, c: Int) {}
            override fun onTextChanged(s: CharSequence?, a: Int, b: Int, c: Int) {
                filter(s?.toString().orEmpty())
            }
            override fun afterTextChanged(s: Editable?) {}
        })

        view.findViewById<FloatingActionButton>(R.id.fab_add).setOnClickListener {
            startActivity(Intent(requireContext(), AddEditActivity::class.java))
        }
    }

    override fun onResume() {
        super.onResume()
        reload()
    }

    private fun reload() {
        filter(view?.findViewById<TextInputEditText>(R.id.search_input)?.text?.toString().orEmpty())
    }

    private fun filter(query: String) {
        val q = query.trim().lowercase()
        val all: List<VaultEntry> = VaultStore.entries
        val filtered = if (q.isEmpty()) all else all.filter {
            it.title.lowercase().contains(q) ||
                it.username.lowercase().contains(q) ||
                it.notes.lowercase().contains(q)
        }
        adapter.submit(filtered)
        emptyView.visibility = if (filtered.isEmpty()) View.VISIBLE else View.GONE
    }
}
