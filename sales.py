import tkinter as tk
from tkinter import ttk, messagebox
import sqlite3
from datetime import datetime

# ============ قاعدة البيانات ============
def init_db():
    conn = sqlite3.connect("sales.db")
    c = conn.cursor()
    # جدول المنتجات
    c.execute("""CREATE TABLE IF NOT EXISTS products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        stock INTEGER NOT NULL
    )""")
    # جدول الفواتير
    c.execute("""CREATE TABLE IF NOT EXISTS invoices(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        total REAL
    )""")
    # جدول بنود الفاتورة
    c.execute("""CREATE TABLE IF NOT EXISTS invoice_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER,
        product_id INTEGER,
        qty INTEGER,
        price REAL,
        FOREIGN KEY(invoice_id) REFERENCES invoices(id),
        FOREIGN KEY(product_id) REFERENCES products(id)
    )""")
    conn.commit()
    conn.close()

# ============ نافذة المنتجات ============
def open_products_window():
    win = tk.Toplevel(root)
    win.title("إدارة المنتجات")
    win.geometry("600x450")

    frame = tk.Frame(win); frame.pack(pady=10)

    tk.Label(frame, text="اسم المنتج").grid(row=0, column=0, padx=5)
    ent_name = tk.Entry(frame, width=20); ent_name.grid(row=0, column=1)

    tk.Label(frame, text="السعر").grid(row=0, column=2, padx=5)
    ent_price = tk.Entry(frame, width=10); ent_price.grid(row=0, column=3)

    tk.Label(frame, text="الكمية").grid(row=0, column=4, padx=5)
    ent_stock = tk.Entry(frame, width=10); ent_stock.grid(row=0, column=5)

    tree = ttk.Treeview(win, columns=("id","name","price","stock"), show="headings", height=15)
    for col, txt in [("id","رقم"),("name","الاسم"),("price","السعر"),("stock","الكمية")]:
        tree.heading(col, text=txt)
        tree.column(col, width=120, anchor="center")
    tree.pack(fill="both", expand=True, padx=10, pady=10)

    def load():
        tree.delete(*tree.get_children())
        conn = sqlite3.connect("sales.db"); c = conn.cursor()
        for row in c.execute("SELECT * FROM products"):
            tree.insert("", "end", values=row)
        conn.close()

    def add():
        try:
            name = ent_name.get().strip()
            price = float(ent_price.get())
            stock = int(ent_stock.get())
            if not name: raise ValueError
            conn = sqlite3.connect("sales.db"); c = conn.cursor()
            c.execute("INSERT INTO products(name,price,stock) VALUES(?,?,?)", (name, price, stock))
            conn.commit(); conn.close()
            load()
            ent_name.delete(0,"end"); ent_price.delete(0,"end"); ent_stock.delete(0,"end")
        except:
            messagebox.showerror("خطأ", "تحقق من البيانات المدخلة")

    def delete():
        sel = tree.selection()
        if not sel: return
        pid = tree.item(sel[0])["values"][0]
        conn = sqlite3.connect("sales.db"); c = conn.cursor()
        c.execute("DELETE FROM products WHERE id=?", (pid,))
        conn.commit(); conn.close()
        load()

    btns = tk.Frame(win); btns.pack(pady=5)
    tk.Button(btns, text="إضافة", bg="#4CAF50", fg="white", width=12, command=add).pack(side="left", padx=5)
    tk.Button(btns, text="حذف المحدد", bg="#f44336", fg="white", width=12, command=delete).pack(side="left", padx=5)

    load()

# ============ نافذة الفاتورة ============
def open_invoice_window():
    win = tk.Toplevel(root)
    win.title("فاتورة بيع جديدة")
    win.geometry("800x600")

    # اختيار المنتج
    top = tk.Frame(win); top.pack(pady=10)
    tk.Label(top, text="المنتج:").pack(side="left", padx=5)
    cb_prod = ttk.Combobox(top, width=30, state="readonly")
    cb_prod.pack(side="left", padx=5)

    tk.Label(top, text="الكمية:").pack(side="left", padx=5)
    ent_qty = tk.Entry(top, width=8); ent_qty.pack(side="left", padx=5)

    # جدول بنود الفاتورة
    tree = ttk.Treeview(win, columns=("pid","name","price","qty","total"), show="headings", height=12)
    for col, txt, w in [("pid","رقم المنتج",80),("name","الاسم",200),
                        ("price","السعر",100),("qty","الكمية",80),("total","الإجمالي",120)]:
        tree.heading(col, text=txt)
        tree.column(col, width=w, anchor="center")
    tree.pack(fill="both", expand=True, padx=10)

    lbl_total = tk.Label(win, text="الإجمالي: 0.00", font=("Arial", 14, "bold"), fg="#2196F3")
    lbl_total.pack(pady=10)

    products_data = {}  # name -> (id, price, stock)
    items = []          # list of (pid, name, price, qty)

    def load_products():
        products_data.clear()
        conn = sqlite3.connect("sales.db"); c = conn.cursor()
        for pid, name, price, stock in c.execute("SELECT id,name,price,stock FROM products"):
            products_data[name] = (pid, price, stock)
        conn.close()
        cb_prod["values"] = list(products_data.keys())

    def add_item():
        name = cb_prod.get()
        if not name:
            messagebox.showwarning("تنبيه", "اختر منتجاً"); return
        try:
            qty = int(ent_qty.get())
            if qty <= 0: raise ValueError
        except:
            messagebox.showerror("خطأ", "كمية غير صحيحة"); return

        pid, price, stock = products_data[name]
        # حساب الكمية المستخدمة من هذا المنتج في الفاتورة
        used = sum(i[3] for i in items if i[0] == pid)
        if qty + used > stock:
            messagebox.showerror("خطأ", f"الكمية غير متوفرة. المتاح: {stock - used}")
            return

        items.append((pid, name, price, qty))
        refresh_tree()

    def refresh_tree():
        tree.delete(*tree.get_children())
        total_all = 0
        for pid, name, price, qty in items:
            line_total = price * qty
            total_all += line_total
            tree.insert("", "end", values=(pid, name, f"{price:.2f}", qty, f"{line_total:.2f}"))
        lbl_total.config(text=f"الإجمالي: {total_all:.2f}")

    def remove_item():
        sel = tree.selection()
        if not sel: return
        idx = tree.index(sel[0])
        items.pop(idx)
        refresh_tree()

    def save_invoice():
        if not items: return
        total = sum(p*q for _,_,p,q in items)
        date = datetime.now().strftime("%Y-%m-%d %H:%M")
        conn = sqlite3.connect("sales.db"); c = conn.cursor()
        c.execute("INSERT INTO invoices(date,total) VALUES(?,?)", (date, total))
        inv_id = c.lastrowid
        for pid, _, price, qty in items:
            c.execute("INSERT INTO invoice_items(invoice_id,product_id,qty,price) VALUES(?,?,?,?)",
                      (inv_id, pid, qty, price))
            c.execute("UPDATE products SET stock = stock - ? WHERE id = ?", (qty, pid))
        conn.commit(); conn.close()
        messagebox.showinfo("نجاح", f"تم حفظ الفاتورة رقم {inv_id}\nالإجمالي: {total:.2f}")
        win.destroy()

    btns = tk.Frame(win); btns.pack(pady=5)
    tk.Button(btns, text="إضافة للفاتورة", bg="#4CAF50", fg="white", width=15, command=add_item).pack(side="left", padx=5)
    tk.Button(btns, text="حذف بند", bg="#FF9800", fg="white", width=15, command=remove_item).pack(side="left", padx=5)
    tk.Button(btns, text="حفظ الفاتورة", bg="#2196F3", fg="white", width=15, command=save_invoice).pack(side="left", padx=5)

    load_products()

# ============ نافذة التقارير ============
def open_reports_window():
    win = tk.Toplevel(root)
    win.title("تقارير المبيعات")
    win.geometry("700x500")

    tree = ttk.Treeview(win, columns=("id","date","total"), show="headings", height=15)
    for col, txt in [("id","رقم الفاتورة"),("date","التاريخ"),("total","الإجمالي")]:
        tree.heading(col, text=txt)
        tree.column(col, width=200, anchor="center")
    tree.pack(fill="both", expand=True, padx=10, pady=10)

    lbl = tk.Label(win, text="", font=("Arial", 13, "bold"), fg="#2196F3")
    lbl.pack(pady=5)

    conn = sqlite3.connect("sales.db"); c = conn.cursor()
    grand = 0
    for row in c.execute("SELECT * FROM invoices ORDER BY id DESC"):
        tree.insert("", "end", values=row)
        grand += row[2]
    conn.close()
    lbl.config(text=f"إجمالي المبيعات الكلي: {grand:.2f}")

# ============ النافذة الرئيسية ============
root = tk.Tk()
root.title("نظام المبيعات")
root.geometry("500x400")
root.configure(bg="#f0f0f0")

tk.Label(root, text="نظام إدارة المبيعات", font=("Arial", 20, "bold"),
         bg="#f0f0f0", fg="#333").pack(pady=30)

def btn(parent, text, color, cmd):
    b = tk.Button(parent, text=text, bg=color, fg="white", width=25, height=2,
                  font=("Arial", 12, "bold"), command=cmd)
    b.pack(pady=8)
    return b

btn(root, "📦 إدارة المنتجات", "#4CAF50", open_products_window)
btn(root, "🧾 إنشاء فاتورة بيع", "#2196F3", open_invoice_window)
btn(root, "📊 تقارير المبيعات", "#FF9800", open_reports_window)
btn(root, "❌ خروج", "#f44336", root.quit)

init_db()
root.mainloop()
