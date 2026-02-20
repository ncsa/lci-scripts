/*************************************************************************
--------------------------------------------------------------------------
--  show_affinity License
--------------------------------------------------------------------------
--
--  show_affinity is licensed under the terms of the MIT license reproduced
--  below. This means that show_affinity is free software and can be used 
--  for both academic and commercial purposes at absolutely no cost.
--
--  ----------------------------------------------------------------------
--
--  Copyright (C) 2017-2019 Lei Huang (huang@tacc.utexas.edu)
--
--  Permission is hereby granted, free of charge, to any person obtaining
--  a copy of this software and associated documentation files (the
--  "Software"), to deal in the Software without restriction, including
--  without limitation the rights to use, copy, modify, merge, publish,
--  distribute, sublicense, and/or sell copies of the Software, and to
--  permit persons to whom the Software is furnished to do so, subject
--  to the following conditions:
--
--  The above copyright notice and this permission notice shall be
--  included in all copies or substantial portions of the Software.
--
--  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
--  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
--  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
--  NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
--  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
--  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
--  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
--  THE SOFTWARE.
--
--------------------------------------------------------------------------
*************************************************************************/

/*
About: This is the source code of show_affinity. It is a Linux tool to query and 
print the binding affinity of the processes of current user on current node. It 
helps users to check whether processes/threads are bound on cores correctly. If 
not, one might observe performance issue due to improper binding. 

To compile,
gcc -Wall -Wextra -o show_affinity show_affinity.c
  
To run the command, 
./show_affinity [all]
	
Without any parameter, show_affinity will only show the results of the processes/
threads of current user that have statuses of running. With "all" as a parameter, 
show_affinity show the results of all processes/threads of current user.
	  
You can run show_affinity with watch if you want to constantly monitor the binding 
affinities of running processes. 
		
Example: watch -n 2 show_affinity all
*/

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>

#define __USE_GNU
#include <sched.h>
#include <errno.h>

// The maximum number of cores on current computer.
#define MAX_CORE		(2048)

// The maximum length of the buffer to hold affinity information
#define LEN_AFFINITY_BUFF	(MAX_CORE*64)

// 256 bytes should be more than enough for one line record. BUFF_SIZE defines the 
// size of the buffer for thread binding affinity info.
#define BUFF_SIZE	(MAX_CORE * 256)

// The number of bytes we read from "/proc/%tid/stat"
#define SIZE_STAT		(256)

// Exhaustively enumerates all processes. 
void enumerate_all_processes(const int show_all);

// Queries whether a thread is running or not with file "/proc/%tid/stat". 
int is_thread_running(const int tid);

// Queries and prints the binding affinity for a given thread. 
int query_task_CPUSet(const int tid, const int is_main_thread, const char msg[]);

// Extracts the executable file name for a given process from "/proc/%pid/stat". 
int extract_exec_name(const int pid, char exec_name[], const int max_str_len);

// Generates a human readable string from an array of bits of cpu binding affinity. 
char *cpulist_create(char *str, const size_t str_len, const cpu_set_t *set, const size_t setsize);


int main(int argc, char *argv[])
{
  // The flag to show all processes of current user or only shows those have running statuses. 
  int show_all = 0;
  
  if ( argc == 2 )
  {
    if ( strncasecmp(argv[1], "all", 4) == 0 )
    {
      show_all = 1;
    }
  }

  // Enumerate allprocesses and print binding affinities. 
  enumerate_all_processes(show_all);
  
  return 0;
}

/*
 * enumerate_all_processes - exhaustively enumerates all processes owned by current user
 *   @show_all: show all processes/threads or only running threads
 * Returns:
 *   void
 */

void enumerate_all_processes(const int show_all)
{
	DIR *dir_root, *dir_proc;
	struct dirent *proc_entry, *thread_entry;
	char path[512], exe_name[512], msg[576];
	struct stat file_stat;
	int pid, tid, thread_count;
	int is_main_thread;
	
	// uid of current user. 
	unsigned int my_uid;
	
	// pid of show_affinity itself. 
	int my_pid;
	
	my_uid = getuid();
	my_pid = getpid();
	
	// The information this code will provide. 1) pid, 2) executable file name 
	// 3) thread id and 4) binding affinity. 
	printf("pid     Exe_Name             tid     Affinity\n");
	
	// the root dir of all running processes
	dir_root = opendir("/proc");
	
	if ( dir_root == NULL )
	{
		perror("Couldn't open the directory /proc.\n");
		return;
	}
	
	while ( 1 )	{
		// loop all entries (processes) under /proc 
		proc_entry = readdir(dir_root);
		
		if ( proc_entry == NULL )	{
			break;
		}
		
		if ( (proc_entry->d_name[0] < '0') || (proc_entry->d_name[0] > '9') )
		{
			// not starting with a number
			continue;
		}
		
		pid = atoi(proc_entry->d_name);

		if ( (pid == 0) || (pid == my_pid) )	{
			// pid == 0: Something wrong in atoi() or directory name. 
			// pid == my_pid: show_affinity itself. 
			continue;
		}

		snprintf(path, sizeof(path), "/proc/%d", pid);
		if ( stat(path, &file_stat) == -1 )	{
			// Error to query the stat of directory path then skip. 
			continue;
		}   
		
		if ( file_stat.st_uid != my_uid )	{
			// Skip the processes not owned by current user
			continue;
		}
		
		snprintf(path, sizeof(path), "/proc/%d/task", pid);
		// enumerates all threads under current process
		
		dir_proc = opendir(path);
		if ( dir_proc == NULL )	{
			printf("Couldn't open the directory %s\n", path);
			continue;
		}
		
		thread_count = 0;
		while ( 1 )	{
			thread_entry = readdir(dir_proc);
			if ( thread_entry == NULL )	{
				break;
			}
			
			if ( (thread_entry->d_name[0] < '0') || (thread_entry->d_name[0] > '9') )	{
				// Not starting with a number then skip. 
				continue;
			}
			
			if ( thread_count == 0 )	{
				// The main thread of this process. Need to query the executable file name 
				// of each process. 
				extract_exec_name(pid, exe_name, sizeof(exe_name));
				
				if ( exe_name[0] == 0 )	{
					// Not a valid name
					continue;
				}
				is_main_thread = 1;
				snprintf(msg, sizeof(msg), "%-6d  %-15s     ", pid, exe_name);
			}
			else	{
				is_main_thread = 0;
			}
			
			tid = atoi(thread_entry->d_name);
			
			if ( show_all || is_thread_running(tid) )
			{
				query_task_CPUSet(tid, is_main_thread, msg);
			}
			
			thread_count++;
		}
		closedir(dir_proc);
		
	}
	closedir(dir_root);
	
}

/*
 * query_task_CPUSet - queries and prints the binding affinity for a given thread. 
 *   @tid: the thread id we need to query binding affinity.
 *   @is_main_thread: is the main thread or not.
 *   @msg: a buffer contains the thread id (of main thread) and executable file name 
 *         if is_main_thread == 1. Otherwise, msg[] is not initialized and used. 
 * Return:
 *   0:success; other:failed
 */

int query_task_CPUSet(const int tid, const int is_main_thread, const char msg[])
{
	char buff_affinity[LEN_AFFINITY_BUFF];
	cpu_set_t my_set;
	
	CPU_ZERO( &my_set );
	
	if ( sched_getaffinity(tid, sizeof(my_set), &my_set) == -1 )
	{
		printf("Failed to get tid %d's affinity. Error no. is %x\nQuit\n", tid, errno);
		return 1;
	}
	
	cpulist_create(buff_affinity, LEN_AFFINITY_BUFF, &my_set, sizeof(my_set));
	if ( is_main_thread )	{
		// The first thread is the main thread. The followings are not, so set *bMainThread zero. 
		printf("%s %-6d  %-43s\n", msg, tid, buff_affinity);
	}
	else	{
		printf("                             %-6d  %-43s\n", tid, buff_affinity);
	}
	return 0;
}

/*
 * is_thread_running - Query whether a thread is running or not with file "/proc/%tid/stat". 
 *   @tid: The thread id to query.
 * Return:
 *   0 - not running; 1 - running
 */

int is_thread_running(const int tid)
{
	int pid, ppid, items_read;
	char buff[SIZE_STAT];
	char path[512], running_status[512], exe_name[512];
	FILE *fp;

	snprintf(path, sizeof(path), "/proc/%d/stat", tid);
	
	fp = fopen(path, "r");
	if ( fp == NULL )	{
		printf("Warning: Error to open file %s\n", path);
		return 0;
	}
	fread(buff, 1, SIZE_STAT, fp);
	fclose(fp);
	
	running_status[0] = 0;

	items_read = sscanf(buff, "%d%s%s%d", &pid, exe_name, running_status, &ppid);
	if( items_read != 4 )	{
		printf("Warning: Unexpected content. %s\nnItemsRead = %d\n", buff, items_read);
	}
	
	if( running_status[0] == 'R' )	{
		return 1;
	}
	
	return 0;
}

/*
 * cpulist_create - generates a human readable string from an array of bits of cpu binding affinity. 
 *   @str: The buffer to hold the human readable string. 
 *   @str_len: The max length of str[].
 *   @set: cpu masks from sched_getaffinity(). 
 *   @setsize: the number of bytes set occupies. 
 * Return:
 *   input parameter str, holds the human readable string. 
 */

char *cpulist_create(char *str, const size_t str_len, const cpu_set_t *set, const size_t setsize)
{
	size_t i, j, block_size, left_bytes = str_len;
	// Each byte has 8 bits. 
	size_t max_len_set = 8 * (setsize);
	char *ptr = str;
	int entry_made = 0;
	int written_bytes;
	
	for ( i = 0; i < max_len_set; i++ ) {
		if ( CPU_ISSET_S(i, setsize, set) ) {
			block_size = 0;
			entry_made = 1;
			for ( j = i + 1; j < max_len_set; j++ ) {
				// To determine the size of a block of cores allow current thread to run. Just for a better presentation of results. 
				if ( CPU_ISSET_S(j, setsize, set) )
					block_size++;
				else
					break;
			}
			if ( !block_size )
				written_bytes = snprintf(ptr, left_bytes, "%zu,", i);
			else if ( block_size == 1 ) {
				written_bytes = snprintf(ptr, left_bytes, "%zu,%zu,", i, i + 1);
				i++;
			}
			else {
				written_bytes = snprintf(ptr, left_bytes, "%zu-%zu,", i, i + block_size);
				i += block_size;
			}
			if ( ( written_bytes < 0 ) || ( (size_t) written_bytes >= left_bytes ) )	{
				printf("Error: str[] is not long enough to hold binding affinity info.\n");
				return NULL;
			}
			
			ptr += written_bytes;
			left_bytes -= written_bytes;
		}
	}
	ptr -= entry_made;
	*ptr = '\0';
	
	return str;
}

/*
 * extract_exec_name - extracts the executable file name for a given process from "/proc/%pid/stat". 
 *   @pid - the process id. 
 *   @exe_name - The buffer to hold the executable file name. 
 *   @max_str_len - The maximum allowed length of buffer exe_name.
 * Return:
 *   0: success, exec_name holds the executable file name.
 *   others: failed 
 */

int extract_exec_name(const int pid, char exe_name[], const int max_str_len)
{
	char path[512];
	int i, count=0, read_bytes, max_str_len_allowed = max_str_len-1;
	char buff[SIZE_STAT];
	FILE *fp=NULL;
	
	exe_name[0] = 0;
	
	snprintf(path, sizeof(path), "/proc/%d/stat", pid);
	fp = fopen(path, "r");
	if( fp == NULL )	{
		return 1;
	}

	read_bytes = fread(buff, 1, max_str_len, fp);
	fclose(fp);
	
	// Example of szBuff, "120097 (sshd) "
	
	i = 0;
	while ( i < read_bytes )	{
		// starting with '('
		if( buff[i] == '(' )	{
			break;
		}
		i++;
	}
	if( i >= read_bytes )	{
		return 1;
	}

	i++;
	while( i < read_bytes )	{
		// ending with ')'
		if( buff[i] == ')' )	{
			break;
		}
		else	{
			exe_name[count] = buff[i];
			count++;
			// The buffer is full. 
			if( count >= max_str_len_allowed )	{
				break;
			}
		}
		i++;
	}
	exe_name[count] = 0;

	return 0;
}
