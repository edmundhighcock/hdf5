require 'ffi'
require 'nmatrix'

class Array
  # Allocate an integer64 chunk of memory, copy the contents of 
  # the array into it and return an FFI::MemoryPointer to the memory.
  # The memory will be garbage collected when the pointer goes out of
  # scope. Obviously the array should contain only integers. This method
  # is not fast and shouldn't be used for giant arrays.
  def ffi_mem_pointer_int64
    raise TypeError.new("Array must contain only integers.") if self.find{|el| not el.kind_of? Integer}
    ptr = FFI::MemoryPointer.new(:int64, size)
    ptr.write_array_of_int64(self)
    ptr
  end

  # This method currently assumes that hsize_t is an int64... this needs
  # to be generalised ASAP.
  def ffi_mem_pointer_hsize_t
    ffi_mem_pointer_int64
  end
end

# This is a module for reading and manipulating HDF5 (Hierarchical Data Format) 
# files. At the current time (July 2014) it is capable of basic reading operations.
# However, its use of the FFI library means that extending its capabilities is easy
# and quick. For a basic example see the test file.  
# Basic usage: 
#     file = Hdf5::H5File.new('filename.hdf5')
#     dataset = file.dataset('/path/to/dataset')
#     narray = dataset.narray_all
#     file.close
module Hdf5

  # A module containing functions for relating HDF5 types to the appropriate 
  # FFI symbol. At the moment these are set by hand, but at some point in the 
  # future they should be set dynamically by interrogation of the the library.
  module H5Types
    extend FFI::Library
    class << self
      def herr_t
        :int
      end
      def hid_t
        :int
      end
      def hbool_t
        :uint
      end
      def htri_t
        :int
      end
      def hsize_t
        :size_t
      end
      def h5t_sign_t
        enum [
          :h5t_sgn_error, -1,
          :h5t_sgn_none, 0, # unsigned
          :h5t_sgn_2, 1, # signed
        ]
      end
      def h5t_class_t
        enum [
          :h5t_no_class         , -1,  #*error                                      */
          :h5t_integer          , 0,   #*integer types                              */
          :h5t_float            , 1,   #*floating-point types                       */
          :h5t_time             , 2,   #*date and time types                        */
          :h5t_string           , 3,   #*character string types                     */
          :h5t_bitfield         , 4,   #*bit field types                            */
          :h5t_opaque           , 5,   #*opaque types                               */
          :h5t_compound         , 6,   #*compound types                             */
          :h5t_reference        , 7,   #*reference types                            */
          :h5t_enum    , 8, #*enumeration types                          */
          :h5t_vlen    , 9, #*variable-length types                      */
          :h5t_array           , 10,  #*array types                                */
          :h5t_nclasses                #*this must be last                          */
        ]
      end
    end
  end

  # A module for dynamically interrogating the environment and the library
  # and providing the correct library path etc. Currently very dumb!
  module H5Library
    class << self
      # The location of the hdf5 library. Currently it is assumed to be in 
      # the default linker path.
      def library_path
        'hdf5'
      end
    end
  end

  extend  FFI::Library
  ffi_lib H5Library.library_path
  attach_function :group_open, :H5Gopen2, [H5Types.hid_t, :string, H5Types.hid_t], H5Types.hid_t
  attach_function :get_type, :H5Iget_type, [H5Types.hid_t], H5Types.hid_t
  #
  # Object for wrapping an HDF file. Basic usage: 
  #     file = Hdf5::H5File.new('filename.hdf5')
  #     dataset = file.dataset('/path/to/dataset')
  #     narray = dataset.narray_all
  #     file.close
  #
  class H5File
    class InvalidFile < StandardError; end
    extend  FFI::Library
    ffi_lib H5Library.library_path
    attach_function :basic_is_hdf5, :H5Fis_hdf5, [:string], H5Types.htri_t
    attach_function :basic_open, :H5Fopen, [:string, :uint, H5Types.hid_t], H5Types.hid_t
    attach_function :basic_close, :H5Fclose, [H5Types.hid_t], H5Types.herr_t
    attr_reader :id
    # Open the file with the given filename. Currently read only
    def initialize(filename)
      raise Errno::ENOENT.new("File #{filename} does not exist") unless FileTest.exist?(filename)
      raise InvalidFile.new("File #{filename} is not a valid hdf5 file") unless basic_is_hdf5(filename) > 0
      @filename = filename
      @id = basic_open(filename, 0x0000, 0)
      raise InvalidFile.new("An unknown problem occured opening #{filename}") if @id < 0
    end
    # Is the file a valid hdf5 file
    def is_hdf5?
      basic_is_hdf5(@filename) > 0
    end
    # Close the file
    def close
      basic_close(@id)
    end
    # Return a group object with the given name
    # (relative to the root of the file)
    def group(name)
      return H5Group.open(@id, name)
    end
    # Return a dataset object with the given name
    # (relative to the root of the file)
    def dataset(name)
      return H5Dataset.open(@id, name)
    end
  end
  # Object wrapping an HDF5 Dataset, which contains
  # a set of data, and information about the type of
  # the data elements and the size and shape of the
  # data array.
  class H5Dataset
    class NotFound < StandardError; end
    extend  FFI::Library
    ffi_lib H5Library.library_path
    attach_function :basic_open, :H5Dopen2, [H5Types.hid_t, :string, H5Types.hid_t], H5Types.hid_t
    attach_function :basic_close, :H5Dclose, [H5Types.hid_t], H5Types.herr_t
    attach_function :basic_get_type, :H5Dget_type, [H5Types.hid_t], H5Types.hid_t
    attach_function :basic_get_space, :H5Dget_space, [H5Types.hid_t], H5Types.hid_t
    attach_function :basic_read, :H5Dread, [H5Types.hid_t, H5Types.hid_t, H5Types.hid_t, H5Types.hid_t, H5Types.hid_t, :pointer], H5Types.herr_t
    attach_variable :h5t_native_float_g, :H5T_NATIVE_FLOAT_g, :int
    # Open the dataset. location_id is the id of the parent
    # file or group. Returns and H5Dataset object
    def self.open(location_id, name)
      id = basic_open(location_id, name, 0)
      raise NotFound.new("dataset #{name} not found") if id < 0
      ds = new(id)
      ds
    end
    # Create a new object. id is the id of the HDF5 dataset this wraps.
    # Use H5Dataset.open to open a dataset
    def initialize(id)
      ObjectSpace.define_finalizer(self){H5Dataset.basic_close(id)}
      @id = id
    end
    # Return an H5Datatype object containing information about the type
    # of an individual member of the dataset
    def datatype
      H5Datatype.new(basic_get_type(@id))
    end
    def dataspace
      H5Dataspace.new(basic_get_space(@id))
    end
    # Gives the narray type corresponding to the datatype of the dataset
    # Raises an error for unsupported datatypes.
    # datatypes (basically only works for ints, floats and complexes, where a datatype
    # composed of two floats is assumed to be a complex).
    def narray_type
      #cls = H5Types.h5t_class_t
      h5_sign = datatype.h5_sign
      h5_size = datatype.h5_size
      case datatype.h5_class
      when :h5t_integer
        sign = if h5_sign == :h5t_sgn_2 then "" else "u" end
        dtype = "#{sign}int#{8 * h5_size}"
      when :h5t_float
        dtype = "float#{8 * h5_size}"
      when :h5t_compound
        if datatype.is_complex?
          dtype = "complex#{8 * h5_size}"
        else
          raise "Unsupported datatype for narray: #{h5c}"
        end
      else
        raise "Unsupported datatype for narray: #{h5c}"
      end
      dtype.to_sym
    end
    # Create an NArray of the appropriate size and read the entire 
    # content of the dataset into it. Will not work for complicated 
    # datatypes (basically only works for ints, floats and complexes, where a datatype
    # composed of two floats is assumed to be a complex). There is 
    # scope in the future for writing custom closures for reading in more
    # complex datatypes.
    def narray_all
      narr = NMatrix.new(dataspace.dims.reverse, dtype: narray_type) # Note narray is fortran-style column major
      basic_read(@id, datatype.id, 0, 0, 0, FFI::Pointer.new(narr.data_pointer))
      narr
    end
    # Create an NArray of the appropriate type and size and a subsection of
    # the dataset into it. start_indexes and end_indexes should be arrays 
    # of size ndims. start_indexes should contain the (zero-based) offset
    # of the start of the read, and end_indexes should contain the offset of 
    # the end of the read. Each element of end_indexes can either be a zero
    # based positive offset, or a negative offset where -1 corresponds to the
    # end of the dataset dimension. This function will not work for complicated 
    # datatypes (basically only works for ints, floats and complexes, where a datatype
    # composed of two floats is assumed to be a complex). There is 
    # scope in the future for writing custom closures for reading in more
    # complex datatypes.
    # As an example, consider a two-dimensional 6x10 dataset. 
    #   dataset.narray_read([0,0], [-1,-1]) # would read the whole of the dataset
    #   dataset.narray_read([0,0], [5,9]) # would read the whole of the dataset
    #   dataset.narray_read([0,0], [2,-1]) # would read half the dataset
    #   dataset.narray_read([0,0], [-4,-1]) # would read the same half of the dataset
    #   dataset.narray_read([2,4], [2,4]) # would read one element of the dataset
    def narray_simple_read(start_indexes, end_indexes)
      nd = dataspace.ndims
      raise ArgumentError.new("start_indexes and end_indexes must be of size ndims") unless start_indexes.size == nd and end_indexes.size == nd
      szs = dataspace.dims
      counts = end_indexes.zip(start_indexes.zip(szs)).map{|ei, (si, sz)| ei < 0 ? ei + sz - si + 1 : ei - si + 1}
      dtspce = H5Dataspace.create_simple(counts)
      dtspce.offset_simple(start_indexes)
      narr = NMatrix.new(dtspce.dims.reverse, dtype: narray_type) # Note narray is fortran-style column major
      basic_read(@id, datatype.id, 0, dtspce.id, 0, FFI::Pointer.new(narr.data_pointer))
      narr
    end
    #def array
    #end
  end
  # Object for wrapping an HD5 dataspace, which contains
  # information about the dimensions and size of the dataset
  class H5Dataspace
    attr_reader :id
    extend  FFI::Library
    ffi_lib H5Library.library_path
    attach_function :basic_close, :H5Sclose, [H5Types.hid_t], H5Types.herr_t
    attach_function :basic_get_simple_extent_ndims, :H5Sget_simple_extent_ndims, [H5Types.hid_t], :int
    attach_function :basic_get_simple_extent_dims, :H5Sget_simple_extent_dims, [H5Types.hid_t, :pointer, :pointer], :int
    attach_function :basic_create_simple, :H5Screate_simple, [:int, :pointer, :pointer], H5Types.hid_t
    attach_function :basic_offset_simple, :H5Soffset_simple, [H5Types.hid_t, :pointer], H5Types.herr_t
    # Create a new HDF5 dataspace with the given current and maximum 
    # dimensions. If maximum_dims is omitted it is set to current_dims.
    # Returns an H5Dataspace object wrapping the dataspace
    def self.create_simple(current_dims, maximum_dims=nil)
      maximum_dims ||= current_dims
      raise ArgumentError.new("current_dims and maximum_dims must be the same size") unless current_dims.size == maximum_dims.size
      n = current_dims.size
      #basic_dims = FFI::MemoryPointer.new(H5Types.hsize_t, n)
      #basic_maxdims = FFI::MemoryPointer.new(H5Types.hsize_t, n)
      #basic_dims.write_array_of_type(:size_t, :put_size_t, current_dims)
      #basic_maxdims.write_array_of_type(:size_t, :put_size_t, maximum_dims)
      # Th
      new(basic_create_simple(n, current_dims.ffi_mem_pointer_hsize_t, maximum_dims.ffi_mem_pointer_hsize_t))
    end
    # Create a new H5Dataspace object. id must be the id
    # of a pre-existing HDF5 dataspace.
    def initialize(id)
      ObjectSpace.define_finalizer(self){H5Dataspace.basic_close(id)}
      @id = id
    end
    # Number of dimensions in the dataspace
    def ndims
      basic_get_simple_extent_ndims(@id)
    end
    def basic_dims_maxdims
      basic_dims = FFI::MemoryPointer.new(H5Types.hsize_t, ndims)
      basic_maxdims = FFI::MemoryPointer.new(H5Types.hsize_t, ndims)
      basic_get_simple_extent_dims(@id, basic_dims, basic_maxdims)
      return [basic_dims, basic_maxdims]
    end
    private :basic_dims_maxdims
    # Get the size of the dataspace
    def dims      
      basic_dims_maxdims[0].get_array_of_int64(0, ndims)
    end
    # Get the maximum size of the dataspace
    def maxdims      
      basic_dims_maxdims[1].get_array_of_int64(0, ndims)
    end
    # Set the offset of the dataspace. offsets should be an ndims-sized array
    # of zero-based integer offsets. 
    def offset_simple(offsets)
      raise ArgumentError.new("offsets should have ndims elements") unless offsets.size == ndims
      basic_offset_simple(@id, offsets.ffi_mem_pointer_hsize_t)
    end
  end
  # Object for wrapping an HD5 datatype, which contains
  # information about the type and makeup of an individual element
  # of the dataset, which may be a float or integer, or may be
  # a vast compound type
  class H5Datatype
    extend  FFI::Library
    ffi_lib H5Library.library_path
    attach_function :basic_close, :H5Tclose, [H5Types.hid_t], H5Types.herr_t
    attach_function :basic_get_class, :H5Tget_class, [H5Types.hid_t], H5Types.h5t_class_t
    attach_function :basic_get_size, :H5Tget_size, [H5Types.hid_t], H5Types.hsize_t
    attach_function :basic_get_sign, :H5Tget_sign, [H5Types.hid_t], H5Types.h5t_sign_t
    attach_function :basic_get_nmembers, :H5Tget_nmembers, [H5Types.hid_t], :int
    attach_function :basic_get_member_type, :H5Tget_member_type, [H5Types.hid_t, :uint], H5Types.hid_t
    attr_reader :id
    def initialize(id)
      ObjectSpace.define_finalizer(self){H5Datatype.basic_close(id)}
      @id = id
    end
    def h5_class
      basic_get_class(@id)
    end
    def h5_size
      basic_get_size(@id)
    end
    def h5_sign
      basic_get_sign(@id)
    end
    # The number of members in a compound datatype
    def nmembers
      basic_get_nmembers(@id)
    end
    # We assume that a compound datatype with two floating point members
    # is a complex number. This may want to be revisisted...
    def is_complex?
      nmembers == 2 and member_types.map{|t| t.h5_class} == [:h5t_float, :h5t_float]
    end
    # An array of datatypes of the members of a compound datatype
    def member_types
      nmembers.times.map{|i| self.class.new(basic_get_member_type(@id, i))}
    end
  end

  # Object representing an HDF5 group
  class H5Group
    # Open the group. location_id is the id of the parent
    # file or group
    def self.open(location_id, name)
      return new(Hdf5.basic_group_open(location_id, name, 0))
    end
    def initialize(id)
      @id = id
    end
    def open_group(name)
      return H5Group.open(@id, name)
    end
  end
end
require 'hdf5/hdf5'
