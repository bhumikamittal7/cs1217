#include "types.h"
#include "user.h"
#include "pstat.h"


int main(void)
{
    struct pstat procinfo;
    getpinfo(&procinfo);
    exit();
}