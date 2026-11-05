# تعليمات التشغيل (Usage)

دليل مفصّل لتشغيل الأداة، مع شرح كل أمر. تعمل الأوامر في **PowerShell** أو **CMD**
(موجّه الأوامر)، والصيغة تختلف قليلًا بينهما.

---

## الفروق بين النافذتين

| المفهوم | CMD | PowerShell |
|---|---|---|
| متغيّر مجلد المستخدم | `%USERPROFILE%` | `$env:USERPROFILE` |
| إلغاء حظر ملف | لا يوجد أمر (استخدم الواجهة) | `Unblock-File` |
| تشغيل ملف `.cmd` | اكتب اسمه مباشرةً | `& ".\اسم.cmd"` |

`git` و`schtasks` برنامجان مستقلّان، فيعملان في النافذتين بالصيغة نفسها.

---

## 1) تحميل الأداة أول مرّة

### PowerShell
```powershell
cd "$env:USERPROFILE\Desktop"
git clone https://github.com/Aymanmuslat/ClearMyDefenderHistory.git
cd "$env:USERPROFILE\Desktop\ClearMyDefenderHistory"
```

### CMD
```
cd /d "%USERPROFILE%\Desktop"
git clone https://github.com/Aymanmuslat/ClearMyDefenderHistory.git
cd ClearMyDefenderHistory
```

**الشرح:**
- `cd` = غيّر المجلد الحالي (في CMD يضيف `/d` تغيير القرص لو لزم).
- `git clone` = ينسخ المستودع من GitHub إلى سطح المكتب.

> **بديل دون git:** افتح صفحة المستودع ← زر **Code** الأخضر ← **Download ZIP** ← فُكّ الضغط.

---

## 2) تحديث نسختك (إن كانت موجودة سابقًا)

```
git pull
```
**الشرح:** يجلب آخر نسخة من المستودع ويدمجها في مجلدك المحلي.

---

## 3) إلغاء حظر الملف (غالبًا غير لازم مع git)

### PowerShell
```powershell
Unblock-File ".\ClearMyDefenderHistory.cmd"
```

### CMD (عبر استدعاء PowerShell لسطر واحد)
```
powershell -command "Unblock-File '.\ClearMyDefenderHistory.cmd'"
```

**أو بالواجهة:** انقر الملف بزرّ الفأرة الأيمن ← **Properties** ← **Unblock** ← **OK**.

---

## 4) التشغيل

### PowerShell
```powershell
& ".\ClearMyDefenderHistory.cmd"
```

### CMD (أو نقر مزدوج على الملف)
```
ClearMyDefenderHistory.cmd
```

**ماذا يحدث:**
1. ترتفع الصلاحيات تلقائيًا ← نافذة **UAC** ← اقبلها.
2. تفحص الأداة وجود تهديد **نشط**؛ إن وُجد، تحذّرك وتطلب تأكيدًا صريحًا.
3. تعرض ما ستحذفه وتطلب تأكيد `y`.
4. تُنشئ المهمّة وتسألك عن إعادة التشغيل — اكتب `y`.

---

## 5) التحقق بعد إعادة التشغيل

```
schtasks /query /tn ClearMyDefenderHistory
```
**النتيجة المطلوبة:** `ERROR: The system cannot find the file specified.`
= نجاح (عملت المهمّة مرّة واحدة ثم حذفت نفسها).

ثم افتح **Windows Security ← Virus & threat protection ← Protection history** للتأكد أنها فارغة.

---

## استكشاف الأخطاء

| المشكلة | الحل |
|---|---|
| `'Unblock-File' is not recognized` | أنت في CMD لا PowerShell؛ استخدم صيغة CMD أعلاه |
| `$env:... syntax is incorrect` | أنت في CMD؛ استخدم `%USERPROFILE%` |
| `destination path already exists` | المجلد موجود؛ استخدم `git pull` بدل `git clone` |
| لم يتغيّر التاريخ بعد التشغيل | **أعد تشغيل الحاسوب** — الحذف يتمّ عند الإقلاع فقط |
