//
// queries the C runtime for various information about primitive data types
//
// NOTE: you will need to use a compiler that conforms to the C99 standard
//       in GNU GCC, you can enable this with -std=c99 (or gnu99)
//
//

#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <stdarg.h>
#include <unistd.h>
#include <stdbool.h>
#include <string.h>
#include <inttypes.h>
#include <float.h>
#include <limits.h>
#include <stddef.h>

#define LINE_BUFSZ 1024
#define LINE_WIDTH 100
#define CSYM_WIDTH 20
#define DVAL_WIDTH 21
#define HVAL_WIDTH -27

static const char BITCHAR[] = { '0', '1' };

char *bitstr(const void *x, size_t n/*bits*/)
{
  char *str = calloc(n + 1, sizeof(*str));
  size_t i  = n - 1;

  while (n--)
    str[i - n] = BITCHAR[(*(uint64_t *)x >> n) & 1];

  return str;
}

char *repchar(const char c, size_t n)
{
  char *str = calloc(n + 1, sizeof(*str));

  while (n--)
    str[n] = c;

  return str;
}

void raprintf(const int width, const char *format, ...)
{
  char *line = calloc(width, sizeof(*line));

  va_list args;
  va_start(args, format);
  (void)vsnprintf(line, width, format, args);
  va_end(args);

  printf("%*s", width, line);

  free(line);
}

void printsizes()
{
  char *majorline = repchar('=', LINE_WIDTH);
  char *minorline = repchar('-', LINE_WIDTH);

  puts(majorline);
  printf("%*s\n", LINE_WIDTH - 2, "PRIMITIVE DATA TYPE SIZES");
  puts(majorline);

  putchar('\n');
#if __bool_true_false_are_defined
  puts(minorline);
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "_Bool",                  sizeof(_Bool),                  8 * sizeof(_Bool));
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "bool",                   sizeof(bool),                   8 * sizeof(bool));
#endif
  puts(minorline);
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "char",                   sizeof(char),                   8 * sizeof(char));
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "signed char",            sizeof(signed char),            8 * sizeof(signed char));
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "unsigned char",          sizeof(unsigned char),          8 * sizeof(unsigned char));
  puts(minorline);
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "short",                  sizeof(short),                  8 * sizeof(short));
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "short int",              sizeof(short int),              8 * sizeof(short int));
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "signed short",           sizeof(signed short),           8 * sizeof(signed short));
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "signed short int",       sizeof(signed short int),       8 * sizeof(signed short int));
  puts(minorline);
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "unsigned short",         sizeof(unsigned short),         8 * sizeof(unsigned short));
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "unsigned short int",     sizeof(unsigned short int),     8 * sizeof(unsigned short int));
  puts(minorline);
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "int",                    sizeof(int),                    8 * sizeof(int));
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "signed",                 sizeof(signed),                 8 * sizeof(signed));
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "signed int",             sizeof(signed int),             8 * sizeof(signed int));
  puts(minorline);
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "unsigned",               sizeof(unsigned),               8 * sizeof(unsigned));
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "unsigned int",           sizeof(unsigned int),           8 * sizeof(unsigned int));
  puts(minorline);
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "long",                   sizeof(long),                   8 * sizeof(long));
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "long int",               sizeof(long int),               8 * sizeof(long int));
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "signed long",            sizeof(signed long),            8 * sizeof(signed long));
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "signed long int",        sizeof(signed long int),        8 * sizeof(signed long int));
  puts(minorline);
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "unsigned long",          sizeof(unsigned long),          8 * sizeof(unsigned long));
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "unsigned long int",      sizeof(unsigned long int),      8 * sizeof(unsigned long int));
  puts(minorline);
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "long long",              sizeof(long long),              8 * sizeof(long long));
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "long long int",          sizeof(long long int),          8 * sizeof(long long int));
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "signed long long",       sizeof(signed long long),       8 * sizeof(signed long long));
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "signed long long int",   sizeof(signed long long int),   8 * sizeof(signed long long int));
  puts(minorline);
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "unsigned long long",     sizeof(unsigned long long),     8 * sizeof(unsigned long long));
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "unsigned long long int", sizeof(unsigned long long int), 8 * sizeof(unsigned long long int));
  puts(minorline);
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "float",                  sizeof(float),                  8 * sizeof(float));
  puts(minorline);
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "double",                 sizeof(double),                 8 * sizeof(double));
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "long double",            sizeof(long double),            8 * sizeof(long double));
  puts(minorline);
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "intmax_t",               sizeof(intmax_t),               8 * sizeof(intmax_t));
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "uintmax_t",              sizeof(uintmax_t),              8 * sizeof(uintmax_t));
  puts(minorline);
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "size_t",                 sizeof(size_t),                 8 * sizeof(size_t));
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "ssize_t",                sizeof(ssize_t),                8 * sizeof(ssize_t));
  puts(minorline);
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "intptr_t",               sizeof(intptr_t),               8 * sizeof(intptr_t));
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "uintptr_t",              sizeof(uintptr_t),              8 * sizeof(uintptr_t));
  raprintf(LINE_WIDTH, "%s: %2zu bytes (%3zu bits)\n", "ptrdiff_t",              sizeof(ptrdiff_t),              8 * sizeof(ptrdiff_t));
  puts(minorline);

}

void printconsts()
{
  char *majorline = repchar('=', LINE_WIDTH);
  char *minorline = repchar('-', LINE_WIDTH);


  puts(majorline);
  printf("%*s\n", LINE_WIDTH - 2, "TYPE-RELATED CONSTANTS");
  puts(majorline);


#if defined(CHAR_BIT)
  putchar('\n');
  puts(majorline);
  printf("%*s [ %*d | %#*x (%3zu-bit)]\n%s\n" \
             "\tsize of the char type in bits (at least 8 bits)\n",
    CSYM_WIDTH, "CHAR_BIT", DVAL_WIDTH, CHAR_BIT, HVAL_WIDTH, CHAR_BIT, 8 * sizeof(CHAR_BIT),
    minorline);
  puts(majorline);
#endif


#if __bool_true_false_are_defined
  putchar('\n');
  puts(majorline);
  printf("%*s [ %*d | %#*x (%3zu-bit)] /*C99*/\n" \
         "%*s [ %*d | %#*x (%3zu-bit)] /*C99*/\n%s\n" \
             "\tvalues of both boolean states\n",
    CSYM_WIDTH, "true",  DVAL_WIDTH, true,  HVAL_WIDTH, true,  8 * sizeof(true),
    CSYM_WIDTH, "false", DVAL_WIDTH, false, HVAL_WIDTH, false, 8 * sizeof(false),
    minorline);
  puts(majorline);
#endif


#if defined(SCHAR_MIN) && defined(SHRT_MIN) && defined(INT_MIN) && defined(LONG_MIN) && defined(LLONG_MIN)
  putchar('\n');
  puts(majorline);
  printf("%*s [ %*d | %#*x (%3zu-bit)] /*C99*/\n" \
         "%*s [ %*d | %#*x (%3zu-bit)] /*C99*/\n" \
         "%*s [ %*d | %#*x (%3zu-bit)] /*C99*/\n" \
         "%*s [ %*ld | %#*lx (%3zu-bit)] /*C99*/\n" \
         "%*s [ %*lld | %#*llx (%3zu-bit)] /*C99*/\n%s\n" \
             "\tminimum possible value of signed integer types: signed char, signed short, signed\n" \
             "\tint, signed long, signed long long\n",
    CSYM_WIDTH, "SCHAR_MIN", DVAL_WIDTH, SCHAR_MIN, HVAL_WIDTH, SCHAR_MIN, 8 * sizeof(SCHAR_MIN),
    CSYM_WIDTH, "SHRT_MIN",  DVAL_WIDTH, SHRT_MIN,  HVAL_WIDTH, SHRT_MIN,  8 * sizeof(SHRT_MIN),
    CSYM_WIDTH, "INT_MIN",   DVAL_WIDTH, INT_MIN,   HVAL_WIDTH, INT_MIN,   8 * sizeof(INT_MIN),
    CSYM_WIDTH, "LONG_MIN",  DVAL_WIDTH, LONG_MIN,  HVAL_WIDTH, LONG_MIN,  8 * sizeof(LONG_MIN),
    CSYM_WIDTH, "LLONG_MIN", DVAL_WIDTH, LLONG_MIN, HVAL_WIDTH, LLONG_MIN, 8 * sizeof(LLONG_MIN),
    minorline);
  puts(majorline);
#endif


#if defined(SCHAR_MAX) && defined(SHRT_MAX) && defined(INT_MAX) && defined(LONG_MAX) && defined(LLONG_MAX)
  putchar('\n');
  puts(majorline);
  printf("%*s [ %*d | %#*x (%3zu-bit)] /*C99*/\n" \
         "%*s [ %*d | %#*x (%3zu-bit)] /*C99*/\n" \
         "%*s [ %*d | %#*x (%3zu-bit)] /*C99*/\n" \
         "%*s [ %*ld | %#*lx (%3zu-bit)] /*C99*/\n" \
         "%*s [ %*lld | %#*llx (%3zu-bit)] /*C99*/\n%s\n" \
             "\tmaximum possible value of signed integer types: signed char, signed short, signed\n" \
             "\tint, signed long, signed long long\n",
    CSYM_WIDTH, "SCHAR_MAX", DVAL_WIDTH, SCHAR_MAX, HVAL_WIDTH, SCHAR_MAX, 8 * sizeof(SCHAR_MAX),
    CSYM_WIDTH, "SHRT_MAX",  DVAL_WIDTH, SHRT_MAX,  HVAL_WIDTH, SHRT_MAX,  8 * sizeof(SHRT_MAX),
    CSYM_WIDTH, "INT_MAX",   DVAL_WIDTH, INT_MAX,   HVAL_WIDTH, INT_MAX,   8 * sizeof(INT_MAX),
    CSYM_WIDTH, "LONG_MAX",  DVAL_WIDTH, LONG_MAX,  HVAL_WIDTH, LONG_MAX,  8 * sizeof(LONG_MAX),
    CSYM_WIDTH, "LLONG_MAX", DVAL_WIDTH, LLONG_MAX, HVAL_WIDTH, LLONG_MAX, 8 * sizeof(LLONG_MAX),
    minorline);
  puts(majorline);
#endif


#if defined(UCHAR_MAX) && defined(USHRT_MAX) && defined(UINT_MAX) && defined(ULONG_MAX) && defined(ULLONG_MAX)
  putchar('\n');
  puts(majorline);
  printf("%*s [ %*u | %#*x (%3zu-bit)] /*C99*/\n" \
         "%*s [ %*u | %#*x (%3zu-bit)] /*C99*/\n" \
         "%*s [ %*u | %#*x (%3zu-bit)] /*C99*/\n" \
         "%*s [ %*lu | %#*lx (%3zu-bit)] /*C99*/\n" \
         "%*s [ %*llu | %#*llx (%3zu-bit)] /*C99*/\n%s\n" \
             "\tmaximum possible value of unsigned integer types: unsigned char, unsigned short,\n" \
             "\tunsigned int, unsigned long, unsigned long long\n",
    CSYM_WIDTH, "UCHAR_MAX",  DVAL_WIDTH, UCHAR_MAX,  HVAL_WIDTH, UCHAR_MAX,  8 * sizeof(UCHAR_MAX),
    CSYM_WIDTH, "USHRT_MAX",  DVAL_WIDTH, USHRT_MAX,  HVAL_WIDTH, USHRT_MAX,  8 * sizeof(USHRT_MAX),
    CSYM_WIDTH, "UINT_MAX",   DVAL_WIDTH, UINT_MAX,   HVAL_WIDTH, UINT_MAX,   8 * sizeof(UINT_MAX),
    CSYM_WIDTH, "ULONG_MAX",  DVAL_WIDTH, ULONG_MAX,  HVAL_WIDTH, ULONG_MAX,  8 * sizeof(ULONG_MAX),
    CSYM_WIDTH, "ULLONG_MAX", DVAL_WIDTH, ULLONG_MAX, HVAL_WIDTH, ULLONG_MAX, 8 * sizeof(ULLONG_MAX),
    minorline);
  puts(majorline);
#endif


#if defined(CHAR_MIN)
  putchar('\n');
  puts(majorline);
  printf("%*s [ %*d | %#*x (%3zu-bit)]\n%s\n" \
             "\tminimum possible value of char\n",
    CSYM_WIDTH, "CHAR_MIN", DVAL_WIDTH, CHAR_MIN, HVAL_WIDTH, CHAR_MIN, 8 * sizeof(CHAR_MIN),
    minorline);
  puts(majorline);
#endif


#if defined(CHAR_MAX)
  putchar('\n');
  puts(majorline);
  printf("%*s [ %*d | %#*x (%3zu-bit)]\n%s\n" \
             "\tmaximum possible value of char\n",
    CSYM_WIDTH, "CHAR_MAX", DVAL_WIDTH, CHAR_MAX, HVAL_WIDTH, CHAR_MAX, 8 * sizeof(CHAR_MAX),
    minorline);
  puts(majorline);
#endif


#if defined(MB_LEN_MAX)
  putchar('\n');
  puts(majorline);
  printf("%*s [ %*d | %#*x (%3zu-bit)]\n%s\n" \
             "\tmaximum number of bytes in a multibyte character\n",
    CSYM_WIDTH, "MB_LEN_MAX", DVAL_WIDTH, MB_LEN_MAX, HVAL_WIDTH, MB_LEN_MAX, 8 * sizeof(MB_LEN_MAX),
    minorline);
  puts(majorline);
#endif


#if defined(FLT_MIN) && defined(DBL_MIN) && defined(LDBL_MIN)
  putchar('\n');
  puts(majorline);
  printf("%*s [ %#*g | %#*a (%3zu-bit)]\n" \
         "%*s [ %#*lg | %#*la (%3zu-bit)]\n" \
         "%*s [ %#*Lg | %#*La (%3zu-bit)]\n%s\n" \
             "\tminimum normalized positive value of float, double, long double respectively\n",
    CSYM_WIDTH, "FLT_MIN",  DVAL_WIDTH, FLT_MIN,  HVAL_WIDTH, FLT_MIN,  8 * sizeof(FLT_MIN),
    CSYM_WIDTH, "DBL_MIN",  DVAL_WIDTH, DBL_MIN,  HVAL_WIDTH, DBL_MIN,  8 * sizeof(DBL_MIN),
    CSYM_WIDTH, "LDBL_MIN", DVAL_WIDTH, LDBL_MIN, HVAL_WIDTH, LDBL_MIN, 8 * sizeof(LDBL_MIN),
    minorline);
  puts(majorline);
#endif


#if defined(FLT_TRUE_MIN) && defined(DBL_TRUE_MIN) && defined(LDBL_TRUE_MIN)
  putchar('\n');
  puts(majorline);
  printf("%*s [ %#*g | %#*a (%3zu-bit)] /*C11*/\n" \
         "%*s [ %#*lg | %#*la (%3zu-bit)] /*C11*/\n" \
         "%*s [ %#*Lg | %#*La (%3zu-bit)] /*C11*/\n%s\n" \
             "\tminimum positive value of float, double, long double respectively\n",
    CSYM_WIDTH, "FLT_TRUE_MIN",  DVAL_WIDTH, FLT_TRUE_MIN,  HVAL_WIDTH, FLT_TRUE_MIN,  8 * sizeof(FLT_TRUE_MIN),
    CSYM_WIDTH, "DBL_TRUE_MIN",  DVAL_WIDTH, DBL_TRUE_MIN,  HVAL_WIDTH, DBL_TRUE_MIN,  8 * sizeof(DBL_TRUE_MIN),
    CSYM_WIDTH, "LDBL_TRUE_MIN", DVAL_WIDTH, LDBL_TRUE_MIN, HVAL_WIDTH, LDBL_TRUE_MIN, 8 * sizeof(LDBL_TRUE_MIN),
    minorline);
  puts(majorline);
#endif


#if defined(FLT_MAX) && defined(DBL_MAX) && defined(LDBL_MAX)
  putchar('\n');
  puts(majorline);
  printf("%*s [ %#*g | %#*a (%3zu-bit)]\n" \
         "%*s [ %#*lg | %#*la (%3zu-bit)]\n" \
         "%*s [ %#*Lg | %#*La (%3zu-bit)]\n%s\n" \
             "\tmaximum finite value of float, double, long double, respectively\n",
    CSYM_WIDTH, "FLT_MAX",  DVAL_WIDTH, FLT_MAX,  HVAL_WIDTH, FLT_MAX,  8 * sizeof(FLT_MAX),
    CSYM_WIDTH, "DBL_MAX",  DVAL_WIDTH, DBL_MAX,  HVAL_WIDTH, DBL_MAX,  8 * sizeof(DBL_MAX),
    CSYM_WIDTH, "LDBL_MAX", DVAL_WIDTH, LDBL_MAX, HVAL_WIDTH, LDBL_MAX, 8 * sizeof(LDBL_MAX),
    minorline);
  puts(majorline);
#endif


#if defined(FLT_ROUNDS)
  putchar('\n');
  puts(majorline);
  printf("%*s [ %*d | %#*x (%3zu-bit)]\n%s\n" \
             "\trounding mode for floating-point operations\n",
    CSYM_WIDTH, "FLT_ROUNDS", DVAL_WIDTH, FLT_ROUNDS, HVAL_WIDTH, FLT_ROUNDS, 8 * sizeof(FLT_ROUNDS),
    minorline);
  puts(majorline);
#endif


#if defined(FLT_EVAL_METHOD)
  putchar('\n');
  puts(majorline);
  printf("%*s [ %*d | %#*x (%3zu-bit)] /*C99*/\n%s\n" \
             "\tevaluation method of expressions involving different floating-point types\n",
    CSYM_WIDTH, "FLT_EVAL_METHOD", DVAL_WIDTH, FLT_EVAL_METHOD, HVAL_WIDTH, FLT_EVAL_METHOD, 8 * sizeof(FLT_EVAL_METHOD),
    minorline);
  puts(majorline);
#endif


#if defined(FLT_RADIX)
  putchar('\n');
  puts(majorline);
  printf("%*s [ %*d | %#*x (%3zu-bit)]\n%s\n" \
             "\tradix of the exponent in the floating-point types\n",
    CSYM_WIDTH, "FLT_RADIX", DVAL_WIDTH, FLT_RADIX, HVAL_WIDTH, FLT_RADIX, 8 * sizeof(FLT_RADIX),
    minorline);
  puts(majorline);
#endif


#if defined(FLT_DIG) && defined(DBL_DIG) && defined(LDBL_DIG)
  putchar('\n');
  puts(majorline);
  printf("%*s [ %*d | %#*x (%3zu-bit)]\n" \
         "%*s [ %*d | %#*x (%3zu-bit)]\n" \
         "%*s [ %*d | %#*x (%3zu-bit)]\n%s\n" \
             "\tnumber of decimal digits that can be represented without losing precision by float,\n" \
             "\tdouble, long double, respectively\n",
    CSYM_WIDTH, "FLT_DIG",  DVAL_WIDTH, FLT_DIG,  HVAL_WIDTH, FLT_DIG,  8 * sizeof(FLT_DIG),
    CSYM_WIDTH, "DBL_DIG",  DVAL_WIDTH, DBL_DIG,  HVAL_WIDTH, DBL_DIG,  8 * sizeof(DBL_DIG),
    CSYM_WIDTH, "LDBL_DIG", DVAL_WIDTH, LDBL_DIG, HVAL_WIDTH, LDBL_DIG, 8 * sizeof(LDBL_DIG),
    minorline);
  puts(majorline);
#endif


#if defined(FLT_EPSILON) && defined(DBL_EPSILON) && defined(LDBL_EPSILON)
  putchar('\n');
  puts(majorline);
  printf("%*s [ %#*g | %#*a (%3zu-bit)]\n" \
         "%*s [ %#*lg | %#*la (%3zu-bit)]\n" \
         "%*s [ %#*Lg | %#*La (%3zu-bit)]\n%s\n" \
             "\tdifference between 1.0 and the next representable value of float, double, long\n" \
             "\tdouble, respectively\n",
    CSYM_WIDTH, "FLT_EPSILON",  DVAL_WIDTH, FLT_EPSILON,  HVAL_WIDTH, FLT_EPSILON,  8 * sizeof(FLT_EPSILON),
    CSYM_WIDTH, "DBL_EPSILON",  DVAL_WIDTH, DBL_EPSILON,  HVAL_WIDTH, DBL_EPSILON,  8 * sizeof(DBL_EPSILON),
    CSYM_WIDTH, "LDBL_EPSILON", DVAL_WIDTH, LDBL_EPSILON, HVAL_WIDTH, LDBL_EPSILON, 8 * sizeof(LDBL_EPSILON),
    minorline);
  puts(majorline);
#endif


#if defined(FLT_MANT_DIG) && defined(DBL_MANT_DIG) && defined(LDBL_MANT_DIG)
  putchar('\n');
  puts(majorline);
  printf("%*s [ %*d | %#*x (%3zu-bit)]\n" \
         "%*s [ %*d | %#*x (%3zu-bit)]\n" \
         "%*s [ %*d | %#*x (%3zu-bit)]\n%s\n" \
             "\tnumber of FLT_RADIX-base digits in the floating-point significand for types float,\n" \
             "\tdouble, long double, respectively\n",
    CSYM_WIDTH, "FLT_MANT_DIG",  DVAL_WIDTH, FLT_MANT_DIG,  HVAL_WIDTH, FLT_MANT_DIG,  8 * sizeof(FLT_MANT_DIG),
    CSYM_WIDTH, "DBL_MANT_DIG",  DVAL_WIDTH, DBL_MANT_DIG,  HVAL_WIDTH, DBL_MANT_DIG,  8 * sizeof(DBL_MANT_DIG),
    CSYM_WIDTH, "LDBL_MANT_DIG", DVAL_WIDTH, LDBL_MANT_DIG, HVAL_WIDTH, LDBL_MANT_DIG, 8 * sizeof(LDBL_MANT_DIG),
    minorline);
  puts(majorline);
#endif


#if defined(FLT_MIN_EXP) && defined(DBL_MIN_EXP) && defined(LDBL_MIN_EXP)
  putchar('\n');
  puts(majorline);
  printf("%*s [ %*d | %#*x (%3zu-bit)]\n" \
         "%*s [ %*d | %#*x (%3zu-bit)]\n" \
         "%*s [ %*d | %#*x (%3zu-bit)]\n%s\n" \
             "\tminimum negative integer such that FLT_RADIX raised to a power one less than that\n" \
             "\tnumber is a normalized float, double, long double, respectively\n",
    CSYM_WIDTH, "FLT_MIN_EXP",  DVAL_WIDTH, FLT_MIN_EXP,  HVAL_WIDTH, FLT_MIN_EXP,  8 * sizeof(FLT_MIN_EXP),
    CSYM_WIDTH, "DBL_MIN_EXP",  DVAL_WIDTH, DBL_MIN_EXP,  HVAL_WIDTH, DBL_MIN_EXP,  8 * sizeof(DBL_MIN_EXP),
    CSYM_WIDTH, "LDBL_MIN_EXP", DVAL_WIDTH, LDBL_MIN_EXP, HVAL_WIDTH, LDBL_MIN_EXP, 8 * sizeof(LDBL_MIN_EXP),
    minorline);
  puts(majorline);
#endif


#if defined(FLT_MIN_10_EXP) && defined(DBL_MIN_10_EXP) && defined(LDBL_MIN_10_EXP)
  putchar('\n');
  puts(majorline);
  printf("%*s [ %*d | %#*x (%3zu-bit)]\n" \
         "%*s [ %*d | %#*x (%3zu-bit)]\n" \
         "%*s [ %*d | %#*x (%3zu-bit)]\n%s\n" \
             "\tminimum negative integer such that 10 raised to that power is a normalized float,\n" \
             "\tdouble, long double, respectively\n",
    CSYM_WIDTH, "FLT_MIN_10_EXP",  DVAL_WIDTH, FLT_MIN_10_EXP,  HVAL_WIDTH, FLT_MIN_10_EXP,  8 * sizeof(FLT_MIN_10_EXP),
    CSYM_WIDTH, "DBL_MIN_10_EXP",  DVAL_WIDTH, DBL_MIN_10_EXP,  HVAL_WIDTH, DBL_MIN_10_EXP,  8 * sizeof(DBL_MIN_10_EXP),
    CSYM_WIDTH, "LDBL_MIN_10_EXP", DVAL_WIDTH, LDBL_MIN_10_EXP, HVAL_WIDTH, LDBL_MIN_10_EXP, 8 * sizeof(LDBL_MIN_10_EXP),
    minorline);
  puts(majorline);
#endif


#if defined(FLT_MAX_EXP) && defined(DBL_MAX_EXP) && defined(LDBL_MAX_EXP)
  putchar('\n');
  puts(majorline);
  printf("%*s [ %*d | %#*x (%3zu-bit)]\n" \
         "%*s [ %*d | %#*x (%3zu-bit)]\n" \
         "%*s [ %*d | %#*x (%3zu-bit)]\n%s\n" \
             "\tmaximum positive integer such that FLT_RADIX raised to a power one less than that\n" \
             "\tnumber is a normalized float, double, long double, respectively\n",
    CSYM_WIDTH, "FLT_MAX_EXP",  DVAL_WIDTH, FLT_MAX_EXP,  HVAL_WIDTH, FLT_MAX_EXP,  8 * sizeof(FLT_MAX_EXP),
    CSYM_WIDTH, "DBL_MAX_EXP",  DVAL_WIDTH, DBL_MAX_EXP,  HVAL_WIDTH, DBL_MAX_EXP,  8 * sizeof(DBL_MAX_EXP),
    CSYM_WIDTH, "LDBL_MAX_EXP", DVAL_WIDTH, LDBL_MAX_EXP, HVAL_WIDTH, LDBL_MAX_EXP, 8 * sizeof(LDBL_MAX_EXP),
    minorline);
  puts(majorline);
#endif


#if defined(FLT_MAX_10_EXP) && defined(DBL_MAX_10_EXP) && defined(LDBL_MAX_10_EXP)
  putchar('\n');
  puts(majorline);
  printf("%*s [ %*d | %#*x (%3zu-bit)]\n" \
         "%*s [ %*d | %#*x (%3zu-bit)]\n" \
         "%*s [ %*d | %#*x (%3zu-bit)]\n%s\n" \
             "\tmaximum positive integer such that 10 raised to that power is a normalized float,\n" \
             "\tdouble, long double, respectively\n",
    CSYM_WIDTH, "FLT_MAX_10_EXP",  DVAL_WIDTH, FLT_MAX_10_EXP,  HVAL_WIDTH, FLT_MAX_10_EXP,  8 * sizeof(FLT_MAX_10_EXP),
    CSYM_WIDTH, "DBL_MAX_10_EXP",  DVAL_WIDTH, DBL_MAX_10_EXP,  HVAL_WIDTH, DBL_MAX_10_EXP,  8 * sizeof(DBL_MAX_10_EXP),
    CSYM_WIDTH, "LDBL_MAX_10_EXP", DVAL_WIDTH, LDBL_MAX_10_EXP, HVAL_WIDTH, LDBL_MAX_10_EXP, 8 * sizeof(LDBL_MAX_10_EXP),
    minorline);
  puts(majorline);
#endif


#if defined(DECIMAL_DIG)
  putchar('\n');
  puts(majorline);
  printf("%*s [ %*d | %#*x (%3zu-bit)] /*C99*/\n%s\n" \
             "\tminimum number of decimal digits such that any number of the widest supported\n" \
             "\tfloating-point type can be represented in decimal with a precision of DECIMAL_DIG\n" \
             "\tdigits and read back in the original floating-point type without changing its value.\n" \
             "\tDECIMAL_DIG is at least 10.\n",
    CSYM_WIDTH, "DECIMAL_DIG", DVAL_WIDTH, DECIMAL_DIG, HVAL_WIDTH, DECIMAL_DIG, 8 * sizeof(DECIMAL_DIG),
    minorline);
  puts(majorline);
#endif


  putchar('\n');
}

int main(int argc, char *argv[])
{
  printsizes();

  if (argc > 1)
  {
    if (true)
    {
      printconsts();
    }
  }

  return 0;
}
