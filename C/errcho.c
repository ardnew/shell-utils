#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define noop (void)0

static FILE * stream = NULL;

void next(int *i, int argc)
{
  if (++(*i) < argc)
  {
    fputc(' ', stream);
  }
}

int main(int argc, char *argv[])
{
  int newline = 1;
  int c       = 0; 
  int i       = 0;

  stream = stderr;
  opterr = 0;

  while (-1 != (c = getopt(argc, argv, "n")))
  {
    switch (c)
    {
      case 'n':
        newline = 0;
        break;

      default:
        break;
    }
  }

  for (i = optind; i < argc; next(&i, argc))
  {
    fprintf(stream, "%s", argv[i]);
  }

  if (newline)
  {
    fputc('\n', stream);
  }

  return 0;
}
