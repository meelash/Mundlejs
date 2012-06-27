// ----------------------------------------------------------------------------
// ab.c is a wrapper for Apache Benchmark. You have to install ab first, see:
//   http://gwan.ch/faq#benchmarks
// ----------------------------------------------------------------------------
// For max speed, build and run ab.c: gcc ab.c -O2 -o abc -lpthread (and ./abc)
// You can also edit & play this program in one step this way: ./gwan -r ab.c
// ============================================================================
// Benchmark framework to test the (free) G-WAN Web App. Server http://gwan.ch/
// See the How-To here: http://gwan.com/en_apachebench_httperf.html
// ----------------------------------------------------------------------------
//  1) invoke Apache Benchmark (IBM) or HTTPerf (HP) on a concurrency
//     range and collect results in a CSV file suitable for LibreOffice
//     (http://www.documentfoundation.org/download/) charting.
//
//  2) optionally, collects CPU / RAM usage for the specified server:
//     "ab gwan", or "ab nginx" (collect stats for all server instances).
//
// Doing 1) and 2) in the same process reduces the overhead of using different
// processes ('htop' and others consume a lot of CPU resources to report the
// RAM / CPU resources usage because they do many things that we don't need):
//
//    Client          Requests per second              CPU 
// -----------  ------------------------------   ---------------  -----
// Concurrency    min        ave         max      user    kernel   RAM
// -----------  -------    -------     -------   ------   ------  -----
// =>   40,      52658,     56100,      59829,   29.46,   70.54,   4.18
// ============================================================================
// A "CPU load" can either be (a) "System Load" or (b) "Application Load":
//
// (a) "System Load" is what you see in the "system monitor": a process using
//     "100% of the CPU" will consume only "25% of the System" on a 4-Core PC.
//
// (b) "Application Load" is what you see in the "top" command: an application 
//     with 2 processes using respectively 50% and 100% of the CPU is reported 
//     as using 150% of the resources.
//
// Just like for RAM usage, it makes sense to have both information:
//
// (a) the [percentage of System RAM] used by an application.
//
// (b) the [amount of RAM] used by an application.
//
// But as (a) depends on a specific machine: on a 256 GB RAM server, a 256 MB
// memory footprint will be invisible (0.1%) as a percentage of the total RAM.
//
// This is why the more relevant method (b) is used for application benchmarks.
// ----------------------------------------------------------------------------
//      Select your benchmarking tool below:

//#define IBM_APACHEBENCH // the classic, made better by Zeus' author
//#define HP_HTTPERF // HTTPerf, from HP, less practical than ApacheBench
#define LIGHTY_WEIGHTTP // Lighttpd's test, faster than AB (same interface)
                        // but a loooong warm-up and no intermediate output
                        // nor any statistics...
                        //http://redmine.lighttpd.net/projects/weighttp/wiki
#define TRACK_ERRORS    // makes things slower but signals HTTP errors

//      Modify the IP ADDRESS & PORT below to match your server values:

#define IP   "127.0.0.1"
#define PORT "3000"

//       100.html is a 100-byte file initially designed to avoid testing the
//       kernel (I wanted to compare the CPU efficiency of each Web server).
//
//       The ANSI C, C#, Java and PHP scripts used below are available from:
//       http://gwan.ch/source/
//
//       The ITER define can be set to 1 to speed up a test but in that case
//       values are not as reliable as when using more rounds (and using a
//       low ITER[ations] value usually gives lower performances):

#define FROM       0 // range to cover (1 - 1,000 concurrent clients)
#define TO       100 // range to cover (1 - 1,000 concurrent clients)
#define STEP      10 // number of concurrency steps we actually skip
#define ITER      10 // number of iterations (3: worse, average, best)
#define KEEP_ALIVES  // comment this for no-HTTP Keep-Alive tests
#ifdef KEEP_ALIVES
   #define KEEP_ALIVES_STR "-k"
 #else
   #define KEEP_ALIVES_STR ""
#endif 

#ifdef IBM_APACHEBENCH
# define CLI_NAME "ab"
#elif defined HP_HTTPERF
# define CLI_NAME "httperf"
#elif defined LIGHTY_WEIGHTTP
# define CLI_NAME "weighttp"
#endif 
//       Select (uncomment) the URL that you want to test:
//
// ---- Static files ----------------------------------------------------------
// #define URL "/~saleemabdulhamid/test.js" // for apache
// #define URL "/test.js" // for connect
#define URL "/mundlejs/KDApplications/Home.kdapplication/AppController" // for mundlejs
//#define URL "/?fractal"

// ---- G-WAN/C ---------------------------------------------------------------
//#define URL "/?hello"
//#define URL "/?hellox&name=Eva"
//#define URL "/?loan&name=Eva&amount=10000&rate=3.5&term=1"
//#define URL "/?loan&name=Eva&amount=10000&rate=3.5&term=10"
//#define URL "/?loan&name=Eva&amount=10000&rate=3.5&term=50"
//#define URL "/?loan&name=Eva&amount=10000&rate=3.5&term=100"
//#define URL "/?loan&name=Eva&amount=10000&rate=3.5&term=150"
//#define URL "/?loan&name=Eva&amount=10000&rate=3.5&term=500"
//#define URL "/?loan&name=Eva&amount=10000&rate=3.5&term=800"

// ---- Apache/PHP ------------------------------------------------------------
//#define URL "/hello.php"
//#define URL "/loan.php?name=Eva&amount=10000&rate=3.5&term=1"
//#define URL "/loan.php?name=Eva&amount=10000&rate=3.5&term=10"
//#define URL "/loan.php?name=Eva&amount=10000&rate=3.5&term=50"
//#define URL "/loan.php?name=Eva&amount=10000&rate=3.5&term=100"
//#define URL "/loan.php?name=Eva&amount=10000&rate=3.5&term=150"
//#define URL "/loan.php?name=Eva&amount=10000&rate=3.5&term=500"
//#define URL "/loan.php?name=Eva&amount=10000&rate=3.5&term=800"

// ---- GlassFish/Java  -------------------------------------------------------
//#define URL "/hello"
//#define URL "/loan/loan/loan.jsp?name=Eva&amount=10000&rate=3.5&term=1"
//#define URL "/loan/loan/loan.jsp?name=Eva&amount=10000&rate=3.5&term=10"
//#define URL "/loan/loan/loan.jsp?name=Eva&amount=10000&rate=3.5&term=50"
//#define URL "/loan/loan/loan.jsp?name=Eva&amount=10000&rate=3.5&term=100"
//#define URL "/loan/loan/loan.jsp?name=Eva&amount=10000&rate=3.5&term=150"
//#define URL "/loan/loan/loan.jsp?name=Eva&amount=10000&rate=3.5&term=500"
//#define URL "/loan/loan/loan.jsp?name=Eva&amount=10000&rate=3.5&term=800"

// ---- IIS/ASP.Net C# --------------------------------------------------------
//#define URL "/asp/hello.aspx""
//#define URL "/asp/loan.aspx?name=Eva&amount=10000&rate=3.5&term=1"
//#define URL "/asp/loan.aspx?name=Eva&amount=10000&rate=3.5&term=10"
//#define URL "/asp/loan.aspx?name=Eva&amount=10000&rate=3.5&term=50"
//#define URL "/asp/loan.aspx?name=Eva&amount=10000&rate=3.5&term=100"
//#define URL "/asp/loan.aspx?name=Eva&amount=10000&rate=3.5&term=150"
//#define URL "/asp/loan.aspx?name=Eva&amount=10000&rate=3.5&term=500"
//#define URL "/asp/loan.aspx?name=Eva&amount=10000&rate=3.5&term=800"

// your locale settings will need to use a comma or a point for 'rate'
// (using the wrong decimal separator will raise an exception in .Net)

//#define URL "/asp/loan.aspx?name=Eva&amount=10000&rate=3,5&term=1"
//#define URL "/asp/loan.aspx?name=Eva&amount=10000&rate=3,5&term=10"
//#define URL "/asp/loan.aspx?name=Eva&amount=10000&rate=3,5&term=50"
//#define URL "/asp/loan.aspx?name=Eva&amount=10000&rate=3,5&term=100"
//#define URL "/asp/loan.aspx?name=Eva&amount=10000&rate=3,5&term=150"
//#define URL "/asp/loan.aspx?name=Eva&amount=10000&rate=3,5&term=500"
//#define URL "/asp/loan.aspx?name=Eva&amount=10000&rate=3,5&term=800"

// ----------------------------------------------------------------------------
// Windows:
// ----------------------------------------------------------------------------
// usage: define _WIN32 below and use a C compiler to compile and link a.c

//#ifndef _WIN32
//# define _WIN32
//#endif
#ifdef _WIN32
# pragma comment(lib, "ws2_32.lib")
# define read(sock, buf, len) recv(sock, buf, len, 0)
# define write(sock, buf, len) send(sock, buf, len, 0)
# define close(sock) closesocket(sock)
#endif

//          Unless you target a localhost test, don't use a Windows machine as
//          the client (to run ab) as the performances are really terrible (ab
//          does not use the 'IO completion ports' Windows proprietary APIs and
//          BSD socket calls are much slower under Windows than on Linux).
//
//          G-WAN for Windows upgrades Registry system values to remove some
//          artificial limits (original values are just renamed), you need to
//          reboot after you run G-WAN for the first time to load those values.
//          Rebooting for each test has an effect on Windows (you are faster),
//          like testing after IIS 7.0 was tested (you are even faster), and
//          the Windows Vista 64-bit TCP/IP stack is 10% faster (for all) if
//          ASP.Net is *not* installed.
//
//          Under Windows, run gwan like this:
//
//              C:\gwan> gwan -b
//
//          The -b flag (optional) disables G-WAN's denial of service shield,
//          this gives better raw performances (this is mandatory for tests
//          under Windows because the overhead of the Denial of Service Shield
//          is breaking the benchmarks).
// ----------------------------------------------------------------------------
// Linux:
// ----------------------------------------------------------------------------
// usage: ./gwan -r ab.c  (a new instance of G-WAN will run this C source code)
//
//          Linux Ubuntu 8.1 did not show significant boot-related side-effects
//          but here also I have had to tune the system (BOTH on the server and
//          client sides).                               ^^^^
//
//          The modification below works after a reboot (if an user is logged):
//          sudo gedit /etc/security/limits.conf
//              * soft nofile 200000
//              * hard nofile 200000
//
//          If you are logged as 'root' in a terminal, type (instant effect):
//              ulimit -HSn 200000
//
/*          sudo gedit /etc/sysctl.conf

                # "Performance Scalability of a Multi-Core Web Server", Nov 2007
                # Bryan Veal and Annie Foong, Intel Corporation, Page 4/10
                fs.file-max = 5000000
                net.core.netdev_max_backlog = 400000
                net.core.optmem_max = 10000000
                net.core.rmem_default = 10000000
                net.core.rmem_max = 10000000
                net.core.somaxconn = 100000
                net.core.wmem_default = 10000000
                net.core.wmem_max = 10000000
                net.ipv4.conf.all.rp_filter = 1
                net.ipv4.conf.default.rp_filter = 1
                net.ipv4.tcp_congestion_control = bic
                net.ipv4.tcp_ecn = 0
                net.ipv4.tcp_max syn backlog = 12000
                net.ipv4.tcp_max tw buckets = 2000000
                net.ipv4.tcp_mem = 30000000 30000000 30000000
                net.ipv4.tcp_rmem = 30000000 30000000 30000000
                net.ipv4.tcp_sack = 1
                net.ipv4.tcp_syncookies = 0
                net.ipv4.tcp_timestamps = 1
                net.ipv4.tcp_wmem = 30000000 30000000 30000000    
                
                # optionally, avoid TIME_WAIT states on localhost no-HTTP Keep-Alive tests:
                #    "error: connect() failed: Cannot assign requested address (99)"
                # On Linux, the 2MSL time is hardcoded to 60 seconds in /include/net/tcp.h:
                # #define TCP_TIMEWAIT_LEN (60*HZ)
                # The option below lets you reduce TIME_WAITs by several orders of magnitude
                # but this option is for benchmarks, NOT for production servers (NAT issues)
                net.ipv4.tcp_tw_recycle = 1
*/
//              # other settings found from various sources
//              fs.file-max = 200000
//              net.ipv4.ip_local_port_range = 1024 65535
//              net.ipv4.ip_forward = 0
//              net.ipv4.conf.default.rp_filter = 1
//              net.core.rmem_max = 262143
//              net.core.rmem_default = 262143
//              net.core.netdev_max_backlog = 32768
//              net.core.somaxconn = 2048
//              net.ipv4.tcp_rmem = 4096 131072 262143
//              net.ipv4.tcp_wmem = 4096 131072 262143
//              net.ipv4.tcp_sack = 0
//              net.ipv4.tcp_dsack = 0
//              net.ipv4.tcp_fack = 0
//              net.ipv4.tcp_fin_timeout = 30
//              net.ipv4.tcp_orphan_retries = 0
//              net.ipv4.tcp_keepalive_time = 120
//              net.ipv4.tcp_keepalive_probes = 3
//              net.ipv4.tcp_keepalive_intvl = 10
//              net.ipv4.tcp_retries2 = 15
//              net.ipv4.tcp_retries1 = 3
//              net.ipv4.tcp_synack_retries = 5
//              net.ipv4.tcp_syn_retries = 5
//              net.ipv4.tcp_timestamps = 0
//              net.ipv4.tcp_max_tw_buckets = 32768
//              net.ipv4.tcp_moderate_rcvbuf = 1
//              kernel.sysrq = 0
//              kernel.shmmax = 67108864
//
//          Use 'sudo sysctl -p /etc/sysctl.conf' to update your environment
//          -the command must be typed in each open terminal for the changes
//          to take place (same effect as a reboot).
//
//          As I was not able to make the 'open files limit' persist for G-WAN
//          after a reboot, G-WAN attemps to setup this to an 'optimal' value
//          depending on the amount of RAM available on your system:
//
//             fd_max = (256 * (totalram / 4) < 200000) ? 256 * (total / 4) 
//                                                      : 1000000;
//
//          For this to work, you have to run gwan as 'root':
//
//              # ./gwan
//              or
//              $ sudo ./gwan
// ----------------------------------------------------------------------------
//          NB: on a 1 GbE LAN and for the for 100.html test, this test was up 
//              to 2x faster when client and server were using Linux 64-bit 
//              (instead of Linux 32-bit) but absolute performances are less 
//              relevant than relative server performances for me, hence the 
//              localhost test).
//
//              Experiments demonstrate that, for a 100-byte static file, IIS
//              and Apache use 90-100% of a 4-Core CPU at high concurrencies 
//              while being much slower than G-WAN (which uses "0%" of the CPU 
//              on a gigabit LAN).
//
//              A low CPU usage matters because leaving free CPU resources
//              available for other tasks allows G-WAN to:
//
//                - achieve better performances by not starving the system;
//                - make room to generate dynamic contents (C servlets);
//                - make room for a database, proxy, email or virtual server;
//                - save energy (CPUs consume more energy under high loads);
//                - save money (doing 20-200,000x more on each of your server).
//
//              For a small static file such as the 100.html file, if your test
//              on a LAN is slower than on localhost then your environment is
//              the bottleneck (NICs, switch, client CPU, client OS...).
// ----------------------------------------------------------------------------
// History
// v1.0.4 changes: initial release to test the whole 1-1,000 concurrency range.
// v1.0.5 changes: added support for non-2xx response codes and trailing stats.
// v1.0.6 changes: corrected 64-bit platform issues and added support for gzip,
//                 dumped a non-2xx reply on stderr for further investigations.
// 2.1.20 changes: added support for HTTPerf as an alternative to ApacheBench.
// 2.4.20 changes: detect & report open (ab.txt output) file permission errors.
// 2.9.26 changes: collects and logs all server's workers CPU and memory usage
//                 (use: "ab gwan", or "ab nginx" to enable this feature).
// 2.10.2 changes: prints sum of user/kernel CPU time, signals weighttp errors,
//                 replaces "pidof " with "ps -C" for not found single-process.
// ----------------------------------------------------------------------------
// This program is left in the public domain.
// ============================================================================
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#ifdef _WIN32
# include <winsock2.h>
# include <process.h>
# include <windows.h>
typedef unsigned __int64 u64;
# define FMTU64 "I64u"
#else
# include <stdint.h>
# include <arpa/inet.h>
# include <ctype.h>
# include <errno.h>
// # include <linux/major.h>
# include <netinet/in.h>
# include <netdb.h>
# include <unistd.h>
# include <sys/param.h>
# include <sys/resource.h>
# include <sys/socket.h>
# include <sys/sysctl.h>
# include <sys/time.h>
# include <sys/types.h>
# include <sys/user.h>
# include <sys/utsname.h>
typedef unsigned int u32;
typedef unsigned long long u64;
# define FMTU64 "llu"

volatile int ab_done = 0;

// ----------------------------------------------------------------------------
// for any reason, 'pidof' fails to list gwan with one process: ./gwan (no -d)
// so we use 'ps -C' as a fallback...
// ----------------------------------------------------------------------------
#ifdef USE_PIDOF 
// ----------------------------------------------------------------------------
// invoke the 'pidof' command and fetch its output, if any:
// "pidof gwan"
// 13937 13936
// ----------------------------------------------------------------------------
int pidsof(char *process_name, u32 **pids)
{
   if(!process_name || !*process_name || !pids)
      return 0;

   char str[4096] = "pidof ";
   strcat(str, process_name);
   
   FILE *f = popen(str, "r");
   if(!f)
      return 0;
   *str = 0;
   char *ok = fgets(str, sizeof(str) - 1, f);
   pclose(f);
   if(!ok)
      return 0;

   u32 *n = *pids = (u32*)malloc(sizeof(u32) * 512), nbr_pids = 0, end = 1;
   char *p = str, *e;
   while(*p)
   {
      e = p;
      while(*e && *e != ' ')
         e++;
      if(*e == ' ')
         *e = 0;
      else
         end = 0;
      n[nbr_pids++] = atoi(p);
      p = e + end;
   }

   *pids = (u32*)realloc(*pids, sizeof(u32) * nbr_pids);
   return nbr_pids;
}
#else
// ----------------------------------------------------------------------------
// If you don't have 'pidof', or if it does not work as expected:
// "ps -C gwan" is equivalent, but the output requires a bit more work:
//   PID TTY          TIME CMD
// 13936 ?        00:00:00 gwan
// 13937 ?        00:00:00 gwan
// ----------------------------------------------------------------------------
int pidsof(char *process_name, u32 **pids)
{
   if(!process_name || !*process_name || !pids)
      return 0;

   char str[4096] = "ps -C ";
   strcat(str, process_name);
   
   FILE *f = popen(str, "r");
   if(!f)
      return 0;
   *str = 0;
   int len = fread(str, 1, sizeof(str) - 1, f);
   pclose(f);
   if(!len)
      return 0;
      
   u32 *n = *pids = (u32*)malloc(sizeof(u32) * 512), nbr_pids = 0, end = 1;
   char *p = str, *e;
   while(*p != '\n') p++; // pass " PID TTY  TIME CMD" header
   if(*p) p++;
   while(*p)
   {
      e = p;
      while(*e && *e == ' ')
         e++;
      while(*e && *e != ' ')
         e++;
      if(*e == ' ')
         *e = 0;

      n[nbr_pids++] = atoi(p);
      p = e + 1;
      while(*p != '\n') p++; // pass " ?  00:00:00 gwan" rest of line
      if(*p) p++;
   }

   *pids = (u32*)realloc(*pids, sizeof(u32) * nbr_pids);
   return nbr_pids;
}
#endif
// ----------------------------------------------------------------------------
// wait 'n' milliseconds
// ----------------------------------------------------------------------------
void msdelay(u32 milisec)
{
   struct timespec req;
   time_t sec = (u32)(milisec / 1000);
   milisec = milisec - (sec * 1000);
   req.tv_sec = sec;
   req.tv_nsec = milisec * 1000000L;
   while(nanosleep(&req, &req) == -1)
      continue;
}
// ----------------------------------------------------------------------------
// update CPU and RAM statistics, only one time per second
// ----------------------------------------------------------------------------
#ifndef _WIN32
typedef struct
{
   u64 user, system;
} icpu_t;
#endif

typedef struct
{
   char   *cpu_buf;
   int     nbr_pids, *pids;
   icpu_t *old_cpu;
} res_args_t;

void th_resources(void *ptr)
{
   res_args_t *arg = (res_args_t*)ptr;
   char *cpu_buf = arg->cpu_buf;
   int nbr_pids = arg->nbr_pids;
   u32 *pids = arg->pids;
   icpu_t *old_cpu = arg->old_cpu;
   
   *cpu_buf = 0;
   char str[32], buffer[256];
   FILE *f;

   msdelay(100); // give time for ab to warm-up the server

   u64 mem = 0, max_mem = 0;
   icpu_t cpu = {0, 0}, max = {0, 0};
   int loop = 80; // 100 + (80 * 10 ms) < 1 second (length of the each ab shot)
   while(loop-- && !ab_done) // loop to track the (varying) RAM usage
   {
      int i = nbr_pids;
      while(i-- && !ab_done) 
      {
         unsigned long new_cpu_user = 0, new_cpu_system = 0;
         sprintf(str, "/proc/%u/stat", pids[i]);
         f = fopen(str, "r");
         char *ok = fgets(buffer, sizeof(buffer) - 1, f);
         fclose(f);
   /*    pid      %d   process ID
         comm     %s   executable filename, in parentheses
         state    %c   R:run, S:sleep, D:wait, Z:zombie, T:traced, W:paging
         ppid     %d   parent's PID
         pgrp     %d   process' group ID
         session  %d   process' session ID
         tty_nr   %d   tty used by the process
         tpgid    %d   parent 'terminal' process' group ID
         flags    %lu  process flags (math bit: 4d, traced bit: 10d)
         minflt   %lu  minor faults that did not load a page from disk
         cminflt  %lu  minor faults that the process + children made
         majflt   %lu  major faults that loaded a page from disk
         cmajflt  %lu  major faults that process + children made
         utime    %lu  jiffies that process has spent in user mode
         stime    %lu  jiffies that process has spent in kernel mode
         cutime   %ld  jiffies that process + children have spent in user mode
         cstime   %ld  jiffies that process + children have spent in kernel mode
         priority %ld  standard nice value, plus fifteen (never negative)
         nice     %ld  nice value ranges from 19 (nicest) to -19 (not nice)
         0        %ld  hard coded to 0 as a placeholder for a removed field
         intvaltm %ld  jiffies before next SIGALRM sent due to an interval timer
         starttm  %lu  jiffies the process started after system boot
         vsize    %lu  virtual memory size in bytes
         rss      %ld  nbr of pages the process has in real memory        */
         char *p = strchr(buffer, ')') + 2;
         if(*p >= 'D' && *p <= 'W') // track a [R]unning process
         {
            p += 2;
            // pass spaces to skip unused variables
            int n = 9;
            while(n)
               if(*p++ == ' ')
                  n--;
            p += 2;
            //printf("\nline:%s\n", p);
            //sscanf(p, "%lu %lu", &new_cpu_user, &new_cpu_system);
            
            // pass spaces to skip unused variables
            n = 10;
            while(n)
               if(*p++ == ' ')
                  n--;
            //printf("\nline:%s\n", p);

            long phys = 0; // physical memory used by process
            sscanf(p, "%ld", &phys);
            mem += (u64)phys << 12llu; // convert 4096-byte pages into bytes
         }
      } // while(i-- && !ab_done)
      
      // we only keep the highest values found during the test
      if(mem > max_mem)
         max_mem = mem;
      
      msdelay(10); // take another measure after a pause
      mem = 0;
   }
   // ------------------------------------------------------------------------
   // now ab is done, get the (always increasing) CPU time
   int i = nbr_pids;
   while(i--) // loop to query all the processes
   {
      unsigned long new_cpu_user = 0, new_cpu_system = 0;
      sprintf(str, "/proc/%u/stat", pids[i]);
      f = fopen(str, "r");
      char *ok = fgets(buffer, sizeof(buffer) - 1, f);
      fclose(f);

      char *p = strchr(buffer, ')') + 2;
      if(*p >= 'D' && *p <= 'W') // track a [R]unning process
      {
         p += 2;
         // pass spaces to skip unused variables
         int n = 9;
         while(n)
            if(*p++ == ' ')
               n--;
         p += 2;
         //printf("\nline:%s\n", p);
         sscanf(p, "%lu %lu", &new_cpu_user, &new_cpu_system);
         
         // pass spaces to skip unused variables
         n = 10;
         while(n)
            if(*p++ == ' ')
               n--;
         //printf("\nline:%s\n", p);

         long phys = 0; // physical memory used by process
         sscanf(p, "%ld", &phys);
         mem += (u64)phys << 12llu; // convert 4096-byte pages into bytes
      }

      cpu.user += new_cpu_user - old_cpu[i].user;
      cpu.system += new_cpu_system - old_cpu[i].system;
      
      old_cpu[i].user = new_cpu_user;
      old_cpu[i].system = new_cpu_system;
   }
   
   // we only keep the highest values found during the test
   if(cpu.user + cpu.system > max.user + max.system)
   {
      max.user = cpu.user;
      max.system = cpu.system;
   }

   if(mem > max_mem)
      max_mem = mem;
   
   /* format cumulated results (user/kernel proportion)
   const double total = (max.user + max.system) / 100.;
   sprintf(cpu_buf, "%7.02f, %7.02f, %7.02f", // User, Kernel, MB RAM
            (max.user / total),// / nbr_cpu, // "System load"
            (max.system / total),// / nbr_cpu, // "System load"
            max_mem / (1024. * 1024.)); */

   // format cumulated results (user/kernel amounts)
   sprintf(cpu_buf, "%7llu, %7llu, %7.02f", // User, Kernel, MB RAM
           max.user,
           max.system,
           max_mem / (1024. * 1024.));
   //puts(cpu_buf);
}
// ----------------------------------------------------------------------------
// invoke a command and fetch its output
// ----------------------------------------------------------------------------
int run_cmd(char *cmd, char *buf, int buflen)
{
   FILE *f = popen(cmd, "r");
   if(!f)
   {
      perror("!run_cmd():");
      return 0;
   }
   *buf = 0;
   int len = fread(buf, 1, buflen, f);
   pclose(f);
   if(!*buf)
      return 0;
   return len;
}
// ------------------------------------
// just a wrapper for the code above
// ------------------------------------
typedef struct
{
   char *cmd, *buf;
   u32 buflen;
} run_cmd_t;

void th_run_cmd(void *ptr)
{
   run_cmd_t *arg = (run_cmd_t*)ptr;
   long len = run_cmd(arg->cmd, arg->buf, arg->buflen);
   pthread_exit((void*)len);
}
// ----------------------------------------------------------------------------
// return the file PATH of process 'name'
// ----------------------------------------------------------------------------
// ps -fC nginx
// root    24569     1 ... nginx: master process /usr/local/nginx/sbin/nginx
// nobody  24570 24569 ... nginx: worker process  
/* ----------------------------------------------------------------------------
char *pid_path(char *name, char *path, int pathlen)
{
   // THIS COMMAND LINE WORKS IN A TERMINAL BUT FAILS HERE... (tip?)
   char cmd[32] = "ps -fC ";
   strcat(cmd, name);
   *path = 0;
   run_cmd(cmd, path, sizeof(path) - 1);
   if(*path)
   {
      printf("%s: %s\n", cmd, path);
      char *p = strchr(path, '/');
      if(p)
         return p;
   }   
   return path;
}*/
// ----------------------------------------------------------------------------
// return the version of a server (providing it supports "server -v")
// ----------------------------------------------------------------------------
// gwan -v   => "\nG-WAN 2.9.16 (Sep 16 2011 13:11:41)"
// nginx -v  => "nginx: nginx version: nginx/1.0.6"
/* ----------------------------------------------------------------------------
char *proc_ver(char *server_name, char *version, int verlen)
{
   // THIS COMMAND LINE WORKS IN A TERMINAL BUT FAILS HERE... (tip?)
   char cmd[256];
   sprintf(cmd, "%s -v", server_name);
   *version = 0;
   run_cmd(cmd, version, verlen);
   if(*version)
   {
      char *p = version;
      while(*p == ' ' || *p == '\t' || *p == '\r' || *p == '\n')
         p++;
      return p;
   }
   return version;
}*/
// ----------------------------------------------------------------------------
// return the physical RAM used by process 'pid'
// ----------------------------------------------------------------------------
u64 pid_ram(u32 pid)
{
   char str[32];
   sprintf(str, "/proc/%u/statm", pid);
   FILE *f = fopen(str, "r");
   if(f)
   {
      unsigned long virt = 0, phys = 0;
      int len = fscanf(f, "%lu %lu", &virt, &phys);
      fclose(f);
      return (u64)phys << 12llu; // convert 4096-byte pages into bytes
   }
   return 0;
}
// ----------------------------------------------------------------------------
// return the free/used physical RAM of the System
// ----------------------------------------------------------------------------
void sys_ram(u64 *free, u64 *total)
{
   *free = 0; *total = 0;
   FILE *f = fopen("/proc/meminfo", "r");
   if(f)
   {
      char buffer[1024];
      while((!*free || !*total) && fgets(buffer, sizeof(buffer), f))
      {
         if(!strncmp(buffer, "MemTotal:", 9))
            *total = atol(buffer + 10);
         else
         if(!strncmp(buffer, "MemFree:", 8))
            *free = atol(buffer + 9);
      }
   }
}
// ----------------------------------------------------------------------------
// print the number and type of CPUs and Cores
// ----------------------------------------------------------------------------
int cpu_type(FILE *fo)
{
   int nbr_cpu = 0, phys_cpu_id = -1, nbr_cores = 0;
   char buffer[1024], model[80] = {0};
   FILE *f = fopen("/proc/cpuinfo", "r");
   if(f)
   {
      while(fgets(buffer, sizeof(buffer), f))
      {
         if(!strncmp(buffer, "processor\t:", 11))
            nbr_cpu++;
         else if(!strncmp(buffer, "physical id\t:", 13))
         {
            int id = atoi(buffer + 14);
            if(id > phys_cpu_id)
               phys_cpu_id = id;
         }
         else if(!*model && !strncmp(buffer, "model name\t:", 12))
         {
            char *s = buffer + 13, *d = model;
            while(*s)
            {
               *d++ = *s;
               if(*s++ == ' ') // copy string removing consecutive spaces
               {
                  while(*s == ' ')
                     s++;
                  *d++ = *s++;
               }
            }
         }
         
         if(!nbr_cores && !strncmp(buffer, "cpu cores\t:", 11))
            nbr_cores = atoi(buffer + 12);
      }
      
      fclose(f);
   }
   
   nbr_cores = 8;
   
   if(nbr_cores > 0)
      nbr_cpu = nbr_cores;
   
   printf("Machine: %d x %u-Core CPU(s) %s", 
          phys_cpu_id >= 0 ? phys_cpu_id + 1 : 1,
          nbr_cores, model);
  fprintf(fo, "Machine: %d x %u-Core CPU(s) %s", 
          phys_cpu_id >= 0 ? phys_cpu_id + 1 : 1,
          nbr_cores, model);
   
   return nbr_cpu << 16 | nbr_cores;
}
#endif
// ============================================================================

static int http_req(char *request);
// ----------------------------------------------------------------------------
// usage: 
// ab         (logs requests per second)
// ab gwan    (logs requests per second, CPU and memory of process 'gwan')
// ----------------------------------------------------------------------------
int main(int argc, char *argv[])
{
   int i, j, nbr, max_rps, min_rps, ave_rps;
   char str[256], buf[4070], buffer[256], cpu_buf[256] = {0};
   time_t st = time(NULL);
   u64 tmax_rps = 0, tmin_rps = 0, tave_rps = 0;
   FILE *f;
   puts(" ");
   
   //fprintf(stderr, "URL=%s\n", URL);
   //fprintf(stderr, "ret=%d\n", http_req(URL));
   //exit(0);

   FILE *fo = fopen("test.txt", "w+b");
   if(!fo)
   {
      perror("can't open output file"); // "Permission denied"
      return 1;
   }
   
   fputs("=============================================================="
         "=================\n"
         "G-WAN ab.c ApacheBench wrapper, http://gwan.ch/source/ab.c.txt\n"
         "--------------------------------------------------------------"
         "-----------------\n", fo);

#ifndef _WIN32
   int nbr_cpu = cpu_type(fo), nbr_cores = nbr_cpu & 0x0000ffff;
   nbr_cpu >>= 16;
   {
      u64 free = 0, total = 0;
      sys_ram(&free, &total);
      if(free && total)
      {
         sprintf(buf, "RAM: %.02f/%.02f (Free/Total, in GB)\n", 
                 free / (1024. * 1024.), total / (1024. * 1024.));
        fputs(buf, fo);
         printf("%s", buf);
      }
   }
   {
      char name[256] = {0};
      f = fopen("/etc/issue", "r");
      if(f)
      {
         int len = fread(name, 1, sizeof(name) - 1, f);
         if(len > 0)
         {
            name[len] = 0; // just in case
            char *p = name;
            while(*p && !iscntrl(*p)) p++; *p = 0;
         }
         fclose(f);
      }
      struct utsname u; uname(&u);      
      sprintf(buf, "%s %s v%s %s\n%s\n\n", 
              u.sysname, u.machine, u.version, u.release, name);
     fputs(buf, fo);
      printf("%s", buf);
   }  
   
   // since servers like Nginx use processes (instead of threads like G-WAN)
   // to implement workers, we have to find all of them
   icpu_t *old_cpu = 0, *beg_cpu = 0;
   int nbr_pids = 0;
   u32 *pids = 0;
   
   if(argv[1]) // any server process name provided on command line?
   {
      sprintf(buf, "> Collecting CPU/RAM stats for server '%s'", argv[1]);
      fputs(buf, fo);
      printf("%s", buf);
      char str[80];
      nbr_pids = pidsof(argv[1], &pids);
      if(nbr_pids)
         old_cpu = (icpu_t*)calloc(nbr_pids, sizeof(icpu_t)),
         beg_cpu = (icpu_t*)calloc(nbr_pids, sizeof(icpu_t));
      sprintf(buf, ": %u process(es)\n", nbr_pids);
      fputs(buf, fo);
      printf("%s", buf);
      int i = nbr_pids;
      while(i--)
      {
         float mem = (float)pid_ram(pids[i]) / (1024. * 1024.);
         sprintf(buf, "pid[%d]:%u RAM: %.02f MB\n", i, pids[i], mem);
         fputs(buf, fo);
         printf("%s", buf);
      }
 
      /* THIS COMMAND LINE WORKS IN A TERMINAL BUT FAILS HERE... (tip?)
      char version[256] = {0};
      proc_ver(argv[1], version, sizeof(version) - 1);
      if(*version)
      {
         printf("version: %s\n", version);
        fprintf(fo, "version: %s\n", version);
      }*/
     fputs(" ", fo);
      puts(" ");
      
      // get the start count of CPU jiffies for this server
      res_args_t res_args = {cpu_buf, nbr_pids, pids, beg_cpu};
      th_resources(&res_args);
   }
   
   fprintf(fo, "\n" CLI_NAME " -n 1000 -c [%u-%u step:%d] "
#ifdef IBM_APACHEBENCH
               "-S -d "
#endif               
#ifdef LIGHTY_WEIGHTTP
               "-t %u "
#endif               
               "%s "
               "\"http://" IP ":" PORT URL "\"\n\n", 
               FROM, TO, STEP, 
#ifdef LIGHTY_WEIGHTTP
               nbr_cores, 
#endif               
               KEEP_ALIVES_STR);
      
#endif
   fputs("  Client           Requests per second               CPU\n" 
   "-----------  -------------------------------  ----------------  -------\n"
   "Concurrency     min        ave        max      user     kernel   MB RAM\n"
   "-----------  ---------  ---------  ---------  -------  -------  -------\n", 
   fo);

   for(i = FROM; i <= TO; i += STEP)
   {
     printf("%d of %d\n", i, TO);
#ifdef IBM_APACHEBENCH
      // ApacheBench makes it straight for you since you can directly tell
      // the 'concurrency' and 'duration' you wish:
      sprintf(str, "ab -n 1000000 -c %d -S -d -t 1 %s "
                   "-H \"Accept-Encoding: gzip\" " // HTTP compression
                   "\"http://" IP ":" PORT
                   URL "\""
#ifdef _WIN32                    
                   " > ab.txt"
#endif                    
                   , i ? i : 1, KEEP_ALIVES_STR);
#elif defined HP_HTTPERF
      // HTTPerf does not let you specify the 'concurrency'rate:
      //
      //    rate    : number of TCP  connections per second
      //    num-con : number of TCP  connections
      //    num-call: number of HTTP requests
      //
      // If we want 100,000 HTTP requests, we have to calculate how many
      // '--num-conn' and '--num-call' to specify for a given '--rate':
      //
      //   nbr_req = rate * num-call
      //
      //   'num-conn' makes it last longer, but to get any given 'rate'
      //   'num-conn' must always be >= to 'rate'
      //
      // HTTPerf creates new connections grogressively and only collects
      // statistics after 5 seconds (to let servers 'warm-up' before they
      // are tested). This is NOT reflecting real-life situations where
      // clients send requests on short but intense bursts.
      //
      // Also, HTTPerf's looooong shots make the TIME_WAIT state become a
      // problem if you do any serious concurrency test.
      //
      // Finally, HTTPerf is unable to test client concurrency: if 'rate'
      // is 1 but num-conn is 2 and num-call is 100,000 then you are more
      // than likely to end with concurrent connections because not all
      // requests are processed when the second connection is launched.
      //
      // If you use a smaller num-call value then you are testing the TCP
      // /IP stack rather than the user-mode code of the server.
      //
      // As a result, HTTPerf can only be reliably used without Keep-Alives
      // (with num-call=1)
      //
      sprintf(str, "httperf --server=" IP " --port=" PORT " "
               "--rate=%d "
#ifdef KEEP_ALIVES               
               "--num-conns=%d --num-calls 100000 " // KEEP-ALIVES
#else               
               "--num-conns=1000000 --num-calls 1 " // NO Keep_Alives
#endif               
               "--timeout 5 --hog --uri=\""
               URL "\""
#ifdef _WIN32                    
               " > ab.txt"
#endif                    
               , i?i:1, i?i:1);
#elif defined LIGHTY_WEIGHTTP
      sprintf(str, "weighttp -n 1000 -c %d -t %u %s "
                   "-H \"Accept-Encoding: gzip\" "
                   "\"http://" IP ":" PORT
                   URL "\""
                   // Weighttp rejects concurrency inferior to thread count:
                   , i > nbr_cores ? i : nbr_cores, nbr_cores, KEEP_ALIVES_STR);
#endif
      
      for(max_rps = 0, ave_rps = 0, min_rps = 0xffff0, j = 0; j < ITER; j++)
      {
#ifdef _WIN32
         // Windows needs to take its breath after system() calls (this is not
         // giving any advantage to Windows as all the tests have shown that
         // this OS platform is -by far- the slowest and less scalable of all)
         system(str);
         Sleep(4000);
         // get the information we need from res.txt
         if(!(f = fopen("ab.txt", "rb")))
         {
            printf("Can't open ab.txt output\n");
            return 1;
         }
         //memset(buf, 0, sizeof(buf) - 1);
         *buf = 0;
         nbr = fread(buf, 1, sizeof(buf) - 1, f);
         if(nbr <= 0)
         {
            printf("Can't read ab.txt output\n");
            return 1;
         }
         fclose(f);
#else
         // MUST be done in parallel to 'ab' because otherwise we check the
         // resources consumed by the server AFTER the 'ab' test is done
         if(nbr_pids)
         {
            ab_done = 0;
            run_cmd_t
                     cmd_args = {.cmd = str, .buf = buf, .buflen = sizeof(buf)};
            pthread_t th_ab;
            pthread_create(&th_ab, NULL, th_run_cmd, (void*)&cmd_args);
            
            res_args_t res_args = {cpu_buf, nbr_pids, pids, old_cpu};
            pthread_t th_res;
            pthread_create(&th_res, NULL, th_resources, (void*)&res_args);
            
            void *ret_code;
            pthread_join(th_ab, (void**)&ret_code);
            nbr = (long)ret_code;
            ab_done = 1;
            
            pthread_join(th_res, NULL);
         }
         else
            nbr = run_cmd(str, buf, sizeof(buf));
#endif
         if(nbr > 0 && nbr < sizeof(buf))
            *(buf + nbr) = 0;
         nbr = 0;
         if(*buf)
         {
            // IIS 7.0 quickly stops serving loans and sends error 503 (Service
            // unavailable) at a relatively high rate. If we did not detect it
            // this would be interpreted as a 'boost' in performance while, in
            // fact, IIS is dying. Soon, IIS would really die and we would have
            // to reboot the host: a complete IIS stop/restart has no effect).

            // Other issues to catch here are error 30x (redirects) or 404
            // (not found) on badly configured servers that make users report
            // that their application server is fast when this is not the case.
#ifdef IBM_APACHEBENCH
            char *p = strstr(buf, "Non-2xx responses:");
            if(p) // "Non-2xx responses:      50130"
            {
               char *n;
               p += sizeof("Non-2xx responses:");
               while(*p == ' ' || *p == '\t')
                  p++;
               n = p;
               while(*p >= '0' && *p <= '9')
                  p++;
               *p = 0;
               nbr = atoi(n);
               if(nbr)
               {
                  printf("* Non-2xx responses:%d\n", nbr);
                  fprintf(fo, "* Non-2xx responses:%d\n", nbr);
                  
                  // dump the server reply on stderr for examination
                  http_req(URL);
                  goto end;
               }
            }

            p = strstr(buf, "Requests per second:");
            if(p) // "Requests per second:    16270.00 [#/sec] (mean)"
            {
               char *n;
               p += sizeof("Requests per second:");
               while(*p == ' ' || *p == '\t')
                  p++;
               n = p;
               while(*p >= '0' && *p <= '9')
                  p++;
               *p = 0;
               nbr = atoi(n);
            }
            else
               puts("* 'Requests per second' not found!");
#elif defined HP_HTTPERF
            char *p = strstr(buf, "Reply status:");
            if(p) // "Reply status: 1xx=0 2xx=1000000 3xx=0 4xx=0 5xx=0"
            {
               char *n;
               p += sizeof("Reply status: 1xx=") - 1;

               // we are not interested in "1xx" errors

               if(*p == '0') // pass "2xx=" if no errors
               p = strstr(p, "3xx=");
               if(p && p[4] == '0') // pass "3xx="  if no errors
               p = strstr(p, "4xx=");
               if(p && p[4] == '0') // pass "4xx="  if no errors
               p = strstr(p, "5xx=");
               if(p && p[4] == '0') // pass "5xx="  if no errors
               goto no_errors;

               p+=sizeof("5xx=");

               while(*p == ' ' || *p == '\t') p++; n = p;
               while(*p >= '0' && *p <= '9') p++; *p = 0;
               nbr = atoi(n);
               if(nbr)
               {
                  printf("* Non-2xx responses:%d\n", nbr);
                  fprintf(fo, "* Non-2xx responses:%d\n", nbr);

                  // dump the server reply on stderr for examination
                  http_req(URL);
                  goto end;
               }
            }
no_errors:
            // Reply rate [replies/s]: min 163943.9 avg 166237.2 max 167482.3
            // stddev 1060.4 (12 samples)
            p = strstr(buf, "Reply rate");
            if(p)
            {
               char *n;
               p += sizeof("Reply rate [replies/s]: min");
               while(*p == ' ' || *p == '\t') p++; n = p;
               while(*p >= '0' && *p <= '9') p++; *p++ = 0; p++;
               min_rps=atoi(n);

               while(*p<'0' || *p>'9') p++; // avg
               n=p;
               while(*p >= '0' && *p <= '9') p++; *p++ = 0; p++;
               ave_rps = atoi(n);

               while(*p < '0' || *p > '9') p++; // max
               n=p;
               while(*p >= '0' && *p <= '9') p++; *p++ = 0; p++;
               max_rps = atoi(n);
            }
            else
            puts("* 'Reply rate' not found!");

            // HTTPerf needs so many more requests than AB that it quickly
            // exhausts the [1 - 65,535] port space. There is no obvious
            // solution other than using several HTTPerf workers OR waiting
            /* a bit between each shot to let the system evacuate the bloat:
            if(!strcmp(IP, "127.0.0.1"))
            {
               int nop = 60;
               printf("waiting:"); fflush(0);
               while(nop--)
               {
                  printf("."); fflush(0);
                  sleep(1);
               }
               printf("\n"); fflush(0);
            }*/
            goto round_done;
            
#elif defined LIGHTY_WEIGHTTP
            char *p = strstr(buf, "microsec,"); // "microsec, 12345 req/s"
            if(p)
            {
               p += sizeof("microsec,");
               nbr = atoi(p);
              
#ifdef TRACK_ERRORS
               p = strstr(p, "succeeded,"); // "succeeded, 0 failed, 0 errored"
               u32 nbr_errors = 0;
               if(p)
               {
                  p += sizeof("succeeded,");
                  nbr_errors = atoi(p);
               }
               if(nbr_errors)
               {
                  printf("* Non-2xx responses:%d\n", nbr);
                  fprintf(fo, "* Non-2xx responses:%d\n", nbr);
                  
                  // dump the server reply on stderr for examination
                  http_req(URL);
                  goto end;
               }
#endif               
            }
            //goto round_done;
#endif
         } // if(nbr_pids)
         
         if(max_rps < nbr)
            max_rps = nbr;
         if(min_rps > nbr)
            min_rps = nbr;
         
         ave_rps += nbr;
         
      } //for(max_rps = 0, ave_rps = 0, min_rps = 0xffff0, j = 0; j < ITER; j++)
      
      ave_rps /= ITER;
#ifndef IBM_APACHEBENCH
round_done:
#endif
      tmin_rps += min_rps;
      tmax_rps += max_rps;
      tave_rps += ave_rps;
      
      // ----------------------------------------------------------------------      
      // display data for convenience and save it on disk
      // ----------------------------------------------------------------------      
      nbr = sprintf(buf, "%10d,%10d,%10d,%10d, %s\n", i ? i : 1, min_rps,
               ave_rps, max_rps, cpu_buf);
      printf("=> %s", buf);
      if(fwrite(buf, 1, nbr, fo) != nbr)
      {
         printf("fwrite(fo) failed");
         return 1;
      }
      fflush(fo); // in case we interrupt the test
   } // for(i = FROM; i <= TO; i += STEP)

end: st = time(NULL) - st;

   strcpy(buf, "---------------------------------------------------------"
               "----------------------");
   puts(buf);
   fputs(buf, fo);
   fputs("\n", fo);

   strftime(str, sizeof(str) - 1, "%X", gmtime(&st));
   sprintf(buf, "min:%"FMTU64"   avg:%"FMTU64"   max:%"FMTU64
   " Time:%ld second(s) [%s]", tmin_rps, tave_rps, tmax_rps, st, str);
   puts(buf);
   fputs(buf, fo);
   fputs("\n", fo);
   
   strcpy(buf, "---------------------------------------------------------"
               "----------------------\n");
   puts(buf);
   fputs(buf, fo);

   if(argv[1]) // any server process name provided on command line?
   {
      // print the total count of CPU jiffies for this server
      u64 user = 0, kernel = 0;
      int i = nbr_pids;
      while(i--)
          user   += (old_cpu[i].user - beg_cpu[i].user),
          kernel += (old_cpu[i].system - beg_cpu[i].system);
          
      sprintf(buf, "CPU jiffies:   user:%"FMTU64"   kernel:%"FMTU64
                   "   total:%"FMTU64,
                   user, kernel, user + kernel);
      puts(buf);
      fputs(buf, fo);
   }

  fputs(" ", fo);
   puts(" ");
   fclose(fo);
   return 0;
}
// ============================================================================
// A 'quick and (really) dirty' wget (don't use this code in production!)
// ----------------------------------------------------------------------------
// read a CRLF-terminated line of text from the socket
// return the number of bytes read, -1 if error
// ----------------------------------------------------------------------------
static int read_line(int fd, char *buffer, int max)
{
   char *p = buffer;
   while(max--)
   {
      if(read(fd, p, 1) <= 0)
         break;
      if(*p == '\r')
         continue;
      if(*p == '\n')
         break;
      p++;
   }
   *p = 0;
   return p - buffer;
}
// ----------------------------------------------------------------------------
// read 'len' bytes from the socket
// return the number of bytes read, -1 if error
// ----------------------------------------------------------------------------
static int read_len(int fd, char *buffer, int len)
{
   int ret;
   char *p = buffer;
   while(len > 0)
   {
      ret = read(fd, p, len);
      if(ret <= 0)
         return -1;
      p += ret;
      len -= ret;
   }
   return p - buffer;
}
// ----------------------------------------------------------------------------
// connect to the server, send the HTTP request and dump the server reply
// return the HTTP status sent by the server, -1 if error
// ----------------------------------------------------------------------------
static int http_req(char *request)
{
   char buf[4096], *p;
   int ret = -1, s, len;
   struct hostent *hp;
   struct sockaddr_in host;
   
#ifdef _WIN32
   WSADATA sa;
   WORD ver = MAKEWORD(2, 2);
   WSAStartup(ver, &sa);
#endif
   
   while((hp = gethostbyname(IP)))
   {
      memset((char*)&host, 0, sizeof(host));
      memmove((char*)&host.sin_addr, hp->h_addr, hp->h_length);
      host.sin_family = hp->h_addrtype;
      host.sin_port = htons((unsigned short)atoi(PORT));
      
      if((s = socket(AF_INET, SOCK_STREAM, 0)) < 0)
         break;

      if(connect(s, (struct sockaddr*)&host, sizeof(host)) < 0)
         break;

      len = sprintf(buf, "GET %s HTTP/1.1\r\n"
         "Host: " IP ":" PORT "\r\n"
      "User-Agent: a.c\r\n"
      "Accept-Encoding: gzip\r\n"
      "Connection: close\r\n\r\n", request);
      
      if(write(s, buf, len) != len)
      {
         break;
      }
      else
      {
         len = read_line(s, buf, sizeof(buf) - 1);
         fputs(buf, stderr);
         putc ('\n',stderr);
         if(len <= 0)
            break;
         else if(sscanf(buf, "HTTP/1.%*d %3d", (int*)&ret) != 1)
            break;
      }

      if(ret > 0) // ret is the HTTP status, parse the server reply
      {
         for(*buf = 0;;)
         {
            int n = read_line(s, buf, sizeof(buf) - 1);
            fputs(buf, stderr);
            putc ('\n',stderr);
            if(n <= 0)
               break;

            for(p = buf; *p && *p != ':'; p++)
               *p = tolower(*p);
            
            sscanf(buf, "content-length: %d", &len);
         }

         len = (len > (sizeof(buf) - 1)) ? (sizeof(buf) - 1) : len;
         len = read_len(s, buf, len);
         if(len > 0)
         {
            buf[len] = 0;
            fputs(buf, stderr);
            putc ('\n',stderr);
         }
      }
      break;
   };

   close(s);
   return ret;
}
// ============================================================================
// End of Source Code
// ============================================================================

