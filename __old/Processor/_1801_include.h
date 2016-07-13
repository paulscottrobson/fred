#define FETCH()  READ(R[P]++)
#define RESET() P = 0;R[0] = 0;IE = 1;DF &= 1
#define ADD(v)  D = temp16 = D + (v);DF = (temp16 >> 8) & 1
#define SUB(n1,n2) D = temp16 = (n1) + ((n2)^0xFF) + 1;DF = (temp16 >> 8) & 1
#define BRANCH(test) if ((test) != 0) R[P] = (R[P] & 0xFF00) | temp8
#define INTERRUPT() T = P | (X << 4);P = 1;X = 2;IE = 0
#define RETURN()  temp8 = READ(R[X]++);P = temp8 & 0xF;X = (temp8 >> 4) & 0xF