
#include "debug.h"
#include "utils.h"
#include <common.h>
#include <elf.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>

//typedef struct
//{
//  Elf32_Word	sh_name;		/* Section name (string tbl index) */
//  Elf32_Word	sh_type;		/* Section type */
//  Elf32_Word	sh_flags;		/* Section flags */
//  Elf32_Addr	sh_addr;		/* Section virtual addr at execution */
//  Elf32_Off	sh_offset;		/* Section file offset */
//  Elf32_Word	sh_size;		/* Section size in bytes */
//  Elf32_Word	sh_link;		/* Link to another section */
//  Elf32_Word	sh_info;		/* Additional section information */
//  Elf32_Word	sh_addralign;		/* Section alignment */
//  Elf32_Word	sh_entsize;		/* Entry size if section holds table */
//} Elf32_Shdr;

static int symtab_ndx = -1;
static int strtab_ndx = -1;
static int func_num = 0;
typedef struct{
	uint32_t st_name;
	Elf32_Addr st_value;
	uint32_t st_size;
}sym_func;
static sym_func* func_table;
static char* str_table;
char no_func[]="???";

static int top = 0;

extern uint64_t function_trace;


void init_elf(const char* elf_file){
	int fread_ret = 0;
	Elf32_Ehdr* f_header = malloc(sizeof(Elf32_Ehdr));
	FILE* fp = fopen(elf_file, "rb");
	Assert(fp, "Failed to open elf_file");
	fread_ret = fread(f_header, sizeof(Elf32_Ehdr), 1, fp);
	Assert(fread_ret==1, "ELF read error!\n");
	// printf("%s\n", f_header->e_ident);

	//获取节头表
	rewind(fp);
	fseek(fp, f_header->e_shoff, SEEK_CUR);
	Elf32_Shdr* section_header = malloc(f_header->e_shnum * sizeof(Elf32_Shdr));
	fread_ret = fread(section_header, sizeof(Elf32_Shdr), f_header->e_shnum, fp);
	Assert(fread_ret==f_header->e_shnum, "ELF read error!\n");

	//获取节名称字符表
	rewind(fp);
	assert(f_header->e_shstrndx);
	// printf("%d\n", f_header->e_shstrndx);
	// printf("%.8x\n", section_header[f_header->e_shstrndx].sh_name);
	char* shstr_table = malloc(section_header[f_header->e_shstrndx].sh_size);
	fseek(fp, section_header[f_header->e_shstrndx].sh_offset, SEEK_CUR);
	fread_ret = fread(shstr_table, section_header[f_header->e_shstrndx].sh_size, 1, fp);
	Assert(fread_ret==1, "ELF read error!\n");
	
	//寻找.symtab和.strtab
	for(int i=0; i<f_header->e_shnum; i++){
		if(!strcmp(shstr_table + section_header[i].sh_name, ".strtab")){
			// printf(".strtab: %d\n", i);
			strtab_ndx = i;
		}
		else if(!strcmp(shstr_table + section_header[i].sh_name, ".symtab")){
			// printf(".symtab: %d\n", i);
			symtab_ndx = i;
		}
			
	}

	//定位并扫描.symtab
	rewind(fp);
	Elf32_Sym* sym_table = malloc(section_header[symtab_ndx].sh_size);
	fseek(fp, section_header[symtab_ndx].sh_offset, SEEK_CUR);
	fread_ret = fread(sym_table, section_header[symtab_ndx].sh_size, 1, fp);
	Assert(fread_ret==1, "ELF read error!\n");
	int sym_num = section_header[symtab_ndx].sh_size / sizeof(Elf32_Sym);
	func_table = malloc(sym_num*sizeof(sym_func));
	assert(func_table);
	for(int i=0; i<sym_num; i++){
		if(ELF32_ST_TYPE(sym_table[i].st_info) == STT_FUNC){
			func_table[func_num++] = (sym_func){.st_name = sym_table[i].st_name,
									  .st_value = sym_table[i].st_value,
									  .st_size = sym_table[i].st_size};
		}
	}
	
	//定位并读取.strtab
	rewind(fp);
	str_table = malloc(section_header[strtab_ndx].sh_size);
	fseek(fp, section_header[strtab_ndx].sh_offset, SEEK_CUR);
	fread_ret = fread(str_table, section_header[strtab_ndx].sh_size, 1, fp);
	Assert(fread_ret==1, "ELF read error!\n");
	
	fclose(fp);
	free(f_header);
	free(section_header);
	free(shstr_table);
	free(sym_table);
}

char* scan_func(Elf32_Addr addr){
	for(int i=0; i<func_num; i++){
		if((addr >= func_table[i].st_value) && (addr < (func_table[i].st_value+func_table[i].st_size))){
			return (str_table+func_table[i].st_name);
		}
	}
	return no_func; 
}

void func_call(Elf32_Addr pc, Elf32_Addr dest){
	Assert(top>=0, "func_call_stack error!\n");
	char* src_func = scan_func(pc);
	char* dest_func = scan_func(dest);
	log_write("0x%.8x: ", pc);
	for(int i =0; i<top; i++){
		log_write("  ");
	}
	log_write("call [%s@0x%.8x] from [%s]\n", dest_func, dest, src_func);
	top++;
	function_trace++;
}

void func_ret(Elf32_Addr pc, Elf32_Addr dest){
	Assert(top>0, "func_ret_stack error!\n");
	char* src_func = scan_func(pc);
	char* dest_func = scan_func(dest);
	log_write("0x%.8x: ", pc);
	for(int i =0; i<top-1; i++){
		log_write("  ");
	}
	log_write("ret [%s] to [%s]\n", src_func, dest_func);
	top--;
	function_trace++;
}


void free_elf_table(){
	free(func_table);
	free(str_table);
}

