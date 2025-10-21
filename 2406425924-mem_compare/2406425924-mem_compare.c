#include <stdio.h> # untuk input standar (printf, etc)
#include <stdlib.h> # untuk malloc(), free(), dan function umum lainnya
#include <string.h> # buat fungsi-fungsi string (sprintf(), etc)
#include <sys/mman.h> # untuk fungsi mmap dan munmap
#include <unistd.h> # untuk read, write, close
#include <fcntl.h> # buat open(), etc
#include <time.h> # untuk membuat timestamp
#include "2406425924-banner.h" # load header custom

// mengambil penggunaan memory dalam satuan kb (kilobyte)
long get_memory_usage_kb(){
	FILE *file = fopen("/proc/self/status", "r"); // membuka file system yang berisi info proses
	char line[256]; 
	long memory = 0;
	
	// membaca tiap barisnya, kemudian mencari baris yang berawalan "VmRSS:" atau yg menunjukkan memory fisik yang sedang digunakan
	while (fgets(line, sizeof(line), file)){
		if (strncmp(line, "VmRSS:", 6) == 0) {
			sscanf(line, "VmRSS: %ld kB", &memory); // ambil angka memory baris tersebut
			break;
		}
	}
	fclose(file);
	return memory; // mengembalikan nilai penggunaan memory (dalam kb)
}

// untuk mmebuat timestamp dalam format YYYYMMDD-HHMMSS
void get_timestamp(char *buffer, size_t size){
	time_t t = time(NULL); // mengambil waktu ketika di eksekusi
	struct tm *tm_info = localtime(&t); // mengubah ke format waktu local
	strftime(buffer, size, "%Y%m%d-%H%M%S", tm_info); // mengubah ke string dan disimpan ke buffer
}

void write_std_file(const char *filename, const char *content){
	FILE *f = fopen(filename, "w"); // membuka file
	fprintf(f, "%s", content); // tulis teks ke file
	fclose(f); // tutup file
}

void write_sys_file(const char *filename, const char *content){
	int fd = open(filename, O_WRONLY | O_CREAT | O_TRUNC, 0644); // buat file langsung tanpa buffer
	write(fd, content, strlen(content)); // menulis langsung ke kernel
	close(fd); // tutup file
}

// membuat dua nama file output otomatis berdasarkan method dan waktu eksekusi
void generate_filename(const char *method, char *std_name, char *sys_name){
	char timestamp[64];
	get_timestamp(timestamp, sizeof(timestamp));
	sprintf(std_name, "2406425924-%s_std-%s.txt", method, timestamp);
	sprintf(sys_name, "2406425924-%s_sys-%s.txt", method, timestamp);
}

// handle malloc method
void handle_malloc() {
    int n;
    printf("Berapa jumlah integer yang ingin dialokasikan? "); // meminta input integer yang ingin dialokasikan
    scanf("%d", &n); // membaca input

    long before = get_memory_usage_kb(); // catat memory sebelum alokasi
    int *arr = (int *)malloc(n * sizeof(int)); // alokasikan n integer
    if (!arr) {
        perror("malloc gagal");
        return;
    }

    // isi array dari n ke 1, sisanya 0
    for (int i = 0; i < n; i++) {
        arr[i] = n - i;
    }

	// catat memory setelah alokasi
    long after = get_memory_usage_kb();

	// print
    char buffer[16384]; 
    int len = sprintf(buffer,
        "======== Method: malloc ========\n\n"
        "Start address: %p\n\n"
        "VmRSS before: %ld kB\n"
        "VmRSS after: %ld kB\n\n"
        "First 100 integers:\n",
        (void*)arr, before, after);

    // cetak 100 integer pertama
    for (int i = 0; i < 100; i++) {
        if (i < n)
            len += sprintf(buffer + len, "arr[%d]: %d\n", i + 1, arr[i]);
        else
            len += sprintf(buffer + len, "arr[%d]: 0\n", i + 1);
    }

    char std_file[128], sys_file[128];
    generate_filename("malloc", std_file, sys_file);

	// menyimpan hasil nya ke dua file
    write_std_file(std_file, buffer);
    write_sys_file(sys_file, buffer);

    free(arr); // membersihkan memory
    printf("Hasil disimpan di %s dan %s\n", std_file, sys_file);
}

// handle mmap method
void handle_mmap() {
    int n;
    printf("Berapa jumlah integer yang ingin dialokasikan? "); // minta input integers
    scanf("%d", &n); // baca input 

    long before = get_memory_usage_kb(); // simpan memory sebelum alokasi
    int *arr = (int *)mmap(NULL, n * sizeof(int), PROT_READ | PROT_WRITE,
                           MAP_PRIVATE | MAP_ANONYMOUS, -1, 0); // alokasi memory dengan set up bisa dibaca dan bisa di tulis
    if (arr == MAP_FAILED) {
        perror("mmap gagal");
        return;
    }

    // isi array dari n ke 1, sisanya 0
    for (int i = 0; i < n; i++) {
        arr[i] = n - i;
    }

	// simpan memory setelah alokasi
    long after = get_memory_usage_kb();

	// print
    char buffer[16384];
    int len = sprintf(buffer,
        "======== Method: mmap ========\n\n"
        "Start address: %p\n\n"
        "VmRSS before: %ld kB\n"
        "VmRSS after: %ld kB\n\n"
        "First 100 integers:\n",
        (void*)arr, before, after);

    for (int i = 0; i < 100; i++) {
        if (i < n)
            len += sprintf(buffer + len, "arr[%d]: %d\n", i + 1, arr[i]);
        else
            len += sprintf(buffer + len, "arr[%d]: 0\n", i + 1);
    }

	// buat bikin dua nama file output yang otomatid di generate berdasarkan method dan waktu eksekusinya
    char std_file[128], sys_file[128];
    generate_filename("mmap", std_file, sys_file);
    write_std_file(std_file, buffer);
    write_sys_file(sys_file, buffer);

    munmap(arr, n * sizeof(int));
    printf("Hasil disimpan di %s dan %s\n", std_file, sys_file);
}


int main(){
	int choice;
	print_banner();

	while (1){
		printf("\nMenu: \n1. Allocate with malloc/free\n2. Allocate with mmap/munmap\n3. Exit\nPilih: ");
		scanf("%d", &choice);

		if (choice == 1){ // kalo pilih menu 1
			handle_malloc();
		} else if (choice == 2){ // kalo pilih menu 2
			handle_mmap();
		} else if (choice == 3){ // kalo pilih menu 3
			break;
		} else {
			printf("Pilihan tidak valid. Coba lagi.\n"); // jika pilihan selain 1 - 3
			return; // kembali meminta input
		}
	}
}