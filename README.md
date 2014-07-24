
Hdf5
====

This is a Ruby module for reading and manipulating HDF5 (Hierarchical Data Format) 
files. At the current time (July 2014) it is capable of basic reading operations.
However, its use of the FFI library means that extending its capabilities is easy
and quick. 

Examples
--------

Basic usage: 

     file = Hdf5::H5File.new('filename.hdf5')
     dataset = file.dataset('/path/to/dataset')
     narray = dataset.narray_all
     file.close

Extended example:


    file = Hdf5::H5File.new('test/field.dat.h5') # Open an existing file readonly

    ds = file.dataset('/field/phi/0000000000')  # Open a dataset
    p ds.narray_type

    p dt = ds.datatype # Access the datatype
    p dt.nmembers # Print the number of members of the datatype

    p dsp = ds.dataspace # Access the dataspace
    p dsp.ndims # Number of dimensions in dataspace
    p dsp.dims # Array of dimension sizes
    p dsp.maxdims # Array of max dimension sizes

    p na = ds.narray_all  # Read the whole dataset into an narray

    p na2 = ds.narray_simple_read([0,0,0], [0,0,0]) # Read one element of the dataset into an narray

    p na3 = ds.narray_simple_read([1,0,0], [3,-1,-1]) # Read a section of the dataset into an narray

    file.close # Close the file
