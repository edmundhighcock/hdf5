require 'ffi'
module Hdf5
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

  extend  FFI::Library
  ffi_lib 'hdf5'
  attach_function :group_open, :H5Gopen2, [H5Types.hid_t, :string, H5Types.hid_t], H5Types.hid_t
  attach_function :get_type, :H5Iget_type, [H5Types.hid_t], H5Types.hid_t
  #
  # Object for wrapping an HDF file
  class H5File
    extend  FFI::Library
    ffi_lib 'hdf5'
    attach_function :basic_is_hdf5, :H5Fis_hdf5, [:string], H5Types.htri_t
    attach_function :basic_open, :H5Fopen, [:string, :uint, H5Types.hid_t], H5Types.hid_t
    attach_function :basic_close, :H5Fclose, [H5Types.hid_t], H5Types.herr_t
    attr_reader :id
    # Open the file with the given filename. Currently read only
    def initialize(filename)
      @filename = filename
      @id = basic_open(filename, 0x0000, 0)
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
    extend  FFI::Library
    ffi_lib 'hdf5'
    attach_function :basic_open, :H5Dopen2, [H5Types.hid_t, :string, H5Types.hid_t], H5Types.hid_t
    attach_function :basic_get_type, :H5Dget_type, [H5Types.hid_t], H5Types.hid_t
    attach_function :basic_get_space, :H5Dget_space, [H5Types.hid_t], H5Types.hid_t
    attach_function :basic_read, :H5Dread, [H5Types.hid_t, H5Types.hid_t, H5Types.hid_t, H5Types.hid_t, H5Types.hid_t, :pointer], H5Types.herr_t
    attach_variable :h5t_native_float_g, :H5T_NATIVE_FLOAT_g, :int
    # Open the dataset. location_id is the id of the parent
    # file or group. Returns and H5Dataset object
    def self.open(location_id, name)
      return new(basic_open(location_id, name, 0))
    end
    # Create a new object. id is the id of the HDF5 dataset this wraps.
    # Use H5Dataset.open to open a dataset
    def initialize(id)
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
    def narray_type
      #cls = H5Types.h5t_class_t
      #p 'datatype', datatype.h5_class
      case datatype.h5_class
      when :h5t_float
        :float
      when :h5t_compound
        if datatype.is_complex?
          :complex
        else
          :compound
        end
      else
        raise "unknown datatype"
      end
    end
      #inline :C do |builder|
        #builder.c <<EOF
        #long asfdsf(){
        #long b;
        #b = 24;
        #return b;}

#EOF
      #end
    def get_narray_pointer(narray)
      p 'p address', narray_data_address(narray)
        #void * narray_pointer(VALUE
      narray_data_address(narray)
    end
    def narray_all
      #p ['ddims', dataspace.dims]
      narr = NArray.send(narray_type, *dataspace.dims)
      #get_narray_pointer(narr)
      ptr = FFI::Pointer.new(narray_data_address(narr))

      #basic_read(@id, self.class.h5t_native_float_g, 0, 0, 0, ptr)
      basic_read(@id, datatype.id, 0, 0, 0, ptr)
      #p ptr.get_array_of_float64(0, 6)
      #p narr.shape
      narr
    end
    #def array
    #end
  end
  # Object for wrapping an HD5 dataspace, which contains
  # information about the dimensions and size of the dataset
  class H5Dataspace
    extend  FFI::Library
    ffi_lib 'hdf5'
    attach_function :basic_get_simple_extent_ndims, :H5Sget_simple_extent_ndims, [H5Types.hid_t], :int
    attach_function :basic_get_simple_extent_dims, :H5Sget_simple_extent_dims, [H5Types.hid_t, :pointer, :pointer], :int
    attach_function :basic_create_simple, :H5Screate_simple, [:int, :pointer, :pointer], H5Types.hid_t
    # Create a new HDF5 dataspace with the given current and maximum 
    # dimensions. If maximum_dims is omitted it is set to current_dims.
    # Returns an H5Dataspace object wrapping the dataspace
    def self.create_simple(current_dims, maximum_dims=nil)
      maximum_dims ||= current_dims
      raise ArgumentError.new("current_dims and maximum_dims must be the same size") unless current_dims.size == maximum_dims.size
      n = current_dims.size
      basic_dims = FFI::MemoryPointer.new(H5Types.hsize_t, n)
      basic_maxdims = FFI::MemoryPointer.new(H5Types.hsize_t, n)
      basic_dims.write_array_of_int64(current_dims)
      basic_maxdims.write_array_of_int64(maximum_dims)
      new(basic_create_simple(n, basic_dims, basic_maxdims))
    end
    # Create a new H5Dataspace object. id must be the id
    # of a pre-existing HDF5 dataspace.
    def initialize(id)
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
    def dims      
      basic_dims_maxdims[0].get_array_of_int64(0, ndims)
    end
    def maxdims      
      basic_dims_maxdims[1].get_array_of_int64(0, ndims)
    end
  end
  # Object for wrapping an HD5 datatype, which contains
  # information about the type and makeup of an individual element
  # of the dataset, which may be a float or integer, or may be
  # a vast compound type
  class H5Datatype
    extend  FFI::Library
    ffi_lib 'hdf5'
    attach_function :basic_get_class, :H5Tget_class, [H5Types.hid_t], H5Types.h5t_class_t
    attach_function :basic_get_nmembers, :H5Tget_nmembers, [H5Types.hid_t], :int
    attach_function :basic_get_member_type, :H5Tget_member_type, [H5Types.hid_t, :uint], H5Types.hid_t
    attr_reader :id
    def initialize(id)
      @id = id
    end
    def h5_class
      basic_get_class(@id)
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
