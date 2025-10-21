```
Nama 	: Nisrina Alya Nabilah
Kelas 	: OS C
NPM 	: 2406425924
```
# Programming Assignment 1

Reference : 
- https://github.com/sokdr/LinuxAudit.git
- https://medium.com/aardvark-infinity/program-title-automated-system-hardening-and-security-audit-script-1e00eb5a577c
- https://github.com/Shoeb-K/Linux-Security-Audit-and-Hardening-Script.git

Script ini melakukan audit keamanan dasar pada sistem Linux dengan memeriksa berbagai konfigurasi keamanan dan menghasilkan laporan.

## Cara Menjalankan
1. Jadikan script dapat dieksekusi menggunakan chmod:
   ```bash
   chmod +x security_audit.sh
   ```
2. Jalankan script dengan hak akses `sudo` supaya bisa memeriksa secara komprehensif:
   ```
   sudo ./security_audit.sh
   ```
3. Script akan memeriksa izin file : File yang diperiksa: `/etc/passwd`,`/etc/shadow`, `/etc/sudoers`
file-file tersebut penting untuk diperiksa karena
	- `/etc/passwd` berisi informasi mengenai akun user. Meskipun perlu dapat dibaca, namun tetap tidak boleh dapat ditulis oleh semua orang karena bisa dimanipulasi untuk menambah akun user tidak sah atau mengubah user privileg.
	- `/etc/shadow` file ini menyimpan hash password. Jika dapat dibaca oleh orang lain, maka attacker bisa melakukan brute force terhadap password yang dapat menyebabkan masalah lain yang lebih rumit
	- `/etc/sudoers` file ini mendefinisikan hak privilege sudo. Perubahan tidak sah dapat menyebabkan eskalasi privilege dan akses root yang tidak diinginkan

4. Pemerikasaan Layanan dan Proses: Proses yang berjalan sebagai root akan mengidentifikasi proses yang berjalan dengan privilege tinggi. layanan jaringan nya juga akan diperiksa apakah ada layanan tidak dikenal yang menyimak di port jaringan. pemeriksaan ini penting karena layanan yang tidak diperlukan akan meningkatkan surface serangan. layanan yang tidak dikenal mungkin menunjukkan malware atau akses tidak sah yang dapat dieksploitasi attackers.

5. Pemeriksaan akun pengguna: Proses ini akan memeriksa `akun tanpa password`, `akun dengan UID 0`, `akun pengguna yang tidak aktif`
	- `akun tanpa password`: karena akun dengan jenis seperti ini dapat dengan mudah disusupi attacker karena tidak memerlukan autentikasi
	- `akun dengan UID 0` : hanya root yang harus memiliki UID 0 untuk privilege superuser, akun lain dengan UID 0 dapat menyebabkan perubahan privilege yang tidak terkontrol oleh attacker
	- `pengguna tidak aktif` : akun dormant mungkin telah dimanipulasi attacker tanpa diketahui dan dapat digunakan sebagai backdoor
	- pemeriksaan ini penting untuk me-manage akun pengguna yang tepat dan akan mencegah akses tidak sah dari perubahan privilege oleh attacker.

6. Pemeriksaan `log sistem` : Kita lihat log auth untuk melihat percobaan login gagal. Banyaknya percobaan login gagal dalam waktu singkat biasanya tanda ada yang mencoba membobol password dengan cara brute force. Kegagalan sudo juga penting diperhatikan karena menunjukkan ada yang mencoba menjalankan perintah admin tanpa hak yang cukup.

7. `Additional checks` : Kita juga periksa file-file sistem yang bisa ditulis oleh siapa saja, versi SSH, dan pengaturan password kosong. File sistem yang bisa diubah oleh siapa saja bisa dimanfaatkan penyerang untuk mengubah sistem atau memasang malware. SSH versi 1 sudah tua dan punya banyak lubang keamanan. Mengizinkan login tanpa password sangat berbahaya karena membuka sistem untuk siapa saja.

8. `Hasil laporan` : Skrip akan membuat dua jenis laporan: tampilan tabel di layar dan file CSV yang berisi detail lengkap dengan saran perbaikan untuk setiap masalah yang ditemukan.

Dengan menjalankan script ini secara rutin, kita bisa menemukan masalah keamanan sebelum dimanfaatkan oleh penyerang, audit ini bsia diibaratkan sebagai  memeriksa pintu dan jendela rumah secara berkala untuk memastikan tidak ada yang bisa dimasuki maling.