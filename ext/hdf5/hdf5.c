#include <math.h>
#include <string.h>
#include <ruby.h>
#include <narray.h>
/*#include "code_runner_ext.h"*/
/*#include <mpi.h>*/
#include <stdbool.h>

/* Taken from the ruby-mpi gem*/
/*struct _Comm {*/
/*MPI_Comm Comm;*/
/*bool free;*/
/*};*/

static VALUE narray_data_address(VALUE class, VALUE narray_obj){

  narray_data_t *narray;
  int addrs;
  VALUE address;

  /*printf("RUNNING TRINITY!!!\n\n");*/
  Data_Get_Struct(narray_obj, struct narray_data_t, narray);
  addrs = (int)narray->ptr;
  address = INT2FIX(addrs);


	/*printf("input file name was %s\n", input_file_name_c);*/
	/**/
	/*free(input_file_name_c);*/

	

	return address;

}

void Init_hdf5()
{
  VALUE ch5_simple_reader;
  /*VALUE ch5_simple_reader_dataset;*/
  
  ch5_simple_reader = rb_const_get(rb_cObject, rb_intern("Hdf5"));
  /*ch5_simple_reader_dataset = rb_const_get(ch5_simple_reader, rb_intern("H5Dataset")); */
  rb_define_singleton_method(ch5_simple_reader, "narray_data_address", narray_data_address, 1);
  /*VALUE ctrinity;*/
  /**/
  /**//**//*cgraph_kit = Qnil;*/
  /*ccode_runner_gs2 = Qnil;*/
  /*ccode_runner_ext = Qnil;*/
  /*printf("HERE!!!\n\n");*/
  /**//*ccode_runner =  RGET_CLASS_TOP("CodeRunner");*/
	/*VALUE ctrinity =  RGET_CLASS_TOP("CodeRunner");*/
  /*ctrinity	= RGET_CLASS(ccode_runner, "Trinity");*/
		/*rb_define_class_under(ccode_runner, "Trinity",*/
		/*RGET_CLASS(*/
		/*RGET_CLASS(ccode_runner, "Run"), */
		/*"FortranNamelist"*/
		/*)*/
		/*);*/

	/*ccode_runner_gs2_gsl_tensor_complexes = rb_define_module_under(ccode_runner_gs2, "GSLComplexTensors");*/
	/*rb_include_module(ccode_runner_gs2, ccode_runner_gs2_gsl_tensor_complexes);*/

	/*ccode_runner_gs2_gsl_tensors = rb_define_module_under(ccode_runner_gs2, "GSLTensors"); */
	/*rb_include_module(ccode_runner_gs2, ccode_runner_gs2_gsl_tensors);*/

	/*cgsl = RGET_CLASS_TOP("GSL");*/
	/*cgsl_vector = RGET_CLASS(cgsl, "Vector");*/
	/*cgsl_vector_complex = RGET_CLASS(cgsl_vector, "Complex");*/

	/*rb_define_method(ccode_runner_gs2_gsl_tensor_complexes, "field_gsl_tensor_complex_2", gs2crmod_tensor_complexes_field_gsl_tensor_complex_2, 1);*/
	/*rb_define_method(ccode_runner_gs2_gsl_tensors, "field_real_space_gsl_tensor", gs2crmod_tensor_field_gsl_tensor, 1);*/
	/*rb_define_method(ccode_runner_gs2_gsl_tensors, "field_correlation_gsl_tensor", gs2crmod_tensor_field_correlation_gsl_tensor, 1);*/

	/*rb_define_method(ccode_runner_ext, "hello_world", code_runner_ext_hello_world, 0);*/
}

