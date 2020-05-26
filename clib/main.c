// cc -O3 -ldl main.c -o main
#include <stdio.h>
#include <dlfcn.h>
#include <stdlib.h>

int main() {
  // Handle for our dynamic library
  void* lib_handle;
  // Function definitions
  void* (*new_evaluator)();
  double (*eval)(void* e, const char* data, int* code);
  void (*free_evaluator)(void* e);

  // Load the library
  lib_handle = dlopen("/home/dian/Projects/nim-snippets/clib/lib.so", RTLD_LAZY);

  if (!lib_handle) {
      fprintf(stderr, "Error during dlopen(): %s\n", dlerror());
      exit(1);
  }
  // Load the symbols
  new_evaluator = dlsym(lib_handle, "new_evaluator");
  eval = dlsym(lib_handle, "eval");
  free_evaluator = dlsym(lib_handle, "free_evaluator");
  // Create a new evaluator
  void* e = new_evaluator();
  int code;
  // Calculate expression
  double res = eval(e, "2+2*2", &code);
  // If non zero - there was an error
  if (code != 0) {
    fprintf(stderr, "eval() failed with error code %i\n", code);
  }
  else {
    printf("%f\n", res);
  }
  // Free the object
  free_evaluator(e);
  // Close the handle
  dlclose(lib_handle);
}