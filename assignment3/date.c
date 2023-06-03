#include "types.h"
#include "user.h"
#include "date.h"
 
int 
main(void) {
    struct rtcdate r;
    if (date(&r)) {
        printf(1, "date failed\n");
        exit();
    }
    printf(1, "Date: %d-%d-%d \nTime: %d:%d:%d\n", r.day, r.month, r.year, r.hour, r.minute, r.second);
    exit();
 }
