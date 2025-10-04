; ===== BREADFANOS CONSTANTS =====
; All system-wide constant definitions

; ===== COLOR CONSTANTS =====
%define BLACK 0
%define BLUE 1
%define GREEN 2
%define CYAN 3
%define RED 4
%define MAGENTA 5
%define BROWN 6
%define LIGHT_GRAY 7
%define DARK_GRAY 8
%define LIGHT_BLUE 9
%define LIGHT_GREEN 10
%define LIGHT_CYAN 11
%define LIGHT_RED 12
%define LIGHT_MAGENTA 13
%define YELLOW 14
%define WHITE 15

; ===== FILE SYSTEM CONSTANTS =====
%define FS_MAX_FILES 8
%define FS_FILENAME_LEN 12
%define FS_ENTRY_SIZE 32
%define FILE_USED 0x01

%define FS_ENTRY_SIZE 32        ; Changed from 16 to 32 bytes per entry
%define FS_NAME_LENGTH 12
%define FS_DATA_START 100       ; File data starts at sector 100

; Directory Entry Structure (16 bytes):
; Bytes 0-11:  Filename (12 chars)
; Byte 12-13:  Start sector (reserved for future use)
; Byte 14:     Flags (FILE_USED = 0x01)
; Byte 15:     Reserved (sector count for future use)

; ===== I/O CONSTANTS =====
DISK_BUFFER_SEG equ 0x1000
HDD_DRIVE equ 0x81
TEST_SECTOR equ 50

