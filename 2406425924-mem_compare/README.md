# 2406425924-mem+compare

**Author:** Nisrina Alya Nabilah
**NPM :** 2406425924
**Course :** Programming Assignment 2 (Memory, Files, and Linking) - Operating System 2025/2026
**Description :** Program ini mengeksplorasi bagaimana program C mengalokasikan dan me-manage memory menggunakan `"malloc/free" `dan `"mmap/munmap"`, mengukur penggunaan memory yang sebenarnya, dan menulis hasil ke file menggunakan 2 cara yang berbeda, yaitu dengan `standard IO librar`y dan juga menggunakan `System Call`

---

## Cara Kerja Program

Saat dijalankan, program akan menampilkan banner dan menu utama berikut:
    ```
    === 2406425924 == Nisrina Alya Nabilah ===
    1. Allocate with malloc/free
    2. Allocate with mmap/munmap
    3. Exit
    ```


### Pilihan 1 – `malloc` / `free`
- Program akan menanyakan berapa banyak integer yang ingin dialokasikan.
- Menggunakan fungsi `malloc()` untuk mengalokasikan memori di **heap**.
- Mengisi array dengan bilangan bulat dalam **urutan terbalik**.  
  Contoh: jika `n = 6` → isi array adalah `6, 5, 4, 3, 2, 1, 0, 0, ...`
- Menampilkan:
  - Alamat awal memori yang dialokasikan.
  - Penggunaan memori (`VmRSS`) sebelum dan sesudah alokasi.
  - 100 nilai pertama dari array (dicetak per baris seperti `arr[1]: 6`).
- Hasil disimpan ke dua file:
  - `2406425924-malloc_std-<TIME>.txt` → menggunakan **Standard I/O**
  - `2406425924-malloc_sys-<TIME>.txt` → menggunakan **System Call**
- Setelah selesai, memori dibebaskan dengan `free()`.

---

### Pilihan 2 – `mmap` / `munmap`
- Langkah-langkahnya sama seperti `malloc`, tetapi menggunakan `mmap()` dan `munmap()`.
- Alokasi dilakukan langsung melalui **virtual memory manager** di kernel Linux.
- Hasil disimpan ke:
  - `2406425924-mmap_std-<TIME>.txt`
  - `2406425924-mmap_sys-<TIME>.txt`

---

### Pilihan 3 – Keluar Program
- Menutup program dengan aman.

---

## Struktur Folder

2406425924-mem_compare/
├── 2406425924-mem_compare.c # Program utama
├── 2406425924-banner.c # File helper untuk menampilkan banner
├── 2406425924-banner.h # Header dari banner
├── Makefile # File untuk kompilasi otomatis
├── 2406425924-malloc_std-<time>.txt # Contoh output standard I/O
├── 2406425924-malloc_sys-<time>.txt # Contoh output system call
├── 2406425924-mmap_std-<time>.txt # Contoh output standard I/O
├── 2406425924-mmap_sys-<time>.txt # Contoh output system call
└── README.md # File penjelasan (file ini)


---

## Cara Kompilasi dan Menjalankan Program

1. Pastikan semua file berada dalam satu folder.  
2. Buka terminal dan masuk ke folder tersebut:
   ```
   cd 2406425924-mem_compare
   make
   ```
   Maka akan terbentuk dua file hasil kompilasi: `2406425924-mem_static`, `2406425924-mem_dynamic`

3. Run salah satu perintah ini: `./2406425924-mem_static` atau `./2406425924-mem_dynamic`

4. Mengikuti instruksi di terminal untuk melakukan alokasi memori dan menyimpan hasilnya ke file

---

## Pengamatan & Analisis
1. Perbandingan malloc vs mmap
    - malloc mengalokasikan memori dari heap, sedangkan mmap langsung memetakan area memori melalui sistem operasi
    - kedua metode menunjukkan peningkatan kecil pada nilai VmRSS (menandakan ada tambahan alokasi memori). 
    - setelah free() atau munmap(), memori kembali berkurang seperti semula.

2. Perbandingan Penulisan File
    - Standard I/O (fopen, fprintf, fclose), lebih mudah digunakan, tapi lebih lambat karena menggunakan buffer.
    - System Call (open, write, close), lebih cepat dan langsung ke kernel, tapi sintaksnya lebih kompleks.

3. Perbedaan Static vs Dynamic Linking
    Setelah menjalankan:
        ```
        ls -lh 2406425924-mem_static 2406425924-mem_dynamic
        ```
    Hasil perbandingan ukuran file:
        -rwxr-xr-x 1 user user 978K Oct 09 13:40 2406425924-mem_static
        -rwxr-xr-x 1 user user  17K Oct 09 13:40 2406425924-mem_dynamic


## Analisis:
1. Versi static linking jauh lebih besar karena seluruh library juga disertakan langsung ke dalam file executable.
2. Versi dynamic linking lebih kecil karena hanya menautkan pustaka saat program dijalankan.