
Hdf5
====

This is a Ruby module for reading and manipulating HDF5 (Hierarchical Data Format) 
files. At the current time (July 2014) it is capable of basic reading operations.
However, its use of the FFI library means that extending its capabilities is easy
and quick. For a basic example see the test/test_hdf5.rb file.  
Basic usage: 
   file = Hdf5::H5File.new('filename.hdf5')
   dataset = file.dataset('/path/to/dataset')
   narray = dataset.narray_all
   file.close
