require 'helper'

class TestHdf5 < Test::Unit::TestCase
  def test_read
    file = Hdf5::H5File.new('test/field.dat.h5') # Open an existing file readonly
    p file.is_hdf5?



    ds = file.dataset('/field/phi/0000000000')  # Open a dataset
    p ds.narray_type

    p dt = ds.datatype # Access the datatype
    p dt.nmembers

    p dsp = ds.dataspace # Access the dataspace
    p dsp.ndims
    p dsp.dims
    p 'maxdims', dsp.maxdims

    p na = ds.narray_all  # Read the whole dataset into an narray
    assert_equal(Complex.rect(-0.05908707447771868, 0.0), na[0,0,0])

    p na2 = ds.narray_simple_read([0,0,0], [0,0,0]) # Read one element of the dataset into an narray
    assert_equal(Complex.rect(-0.05908707447771868, 0.0), na2[0,0,0])

    p na3 = ds.narray_simple_read([1,0,0], [3,-1,-1]) # Read a section of the dataset into an narray
    assert_equal(Complex.rect(-0.06146728043206969, 0.0), na3[0,0,0])
    assert_equal([4,1,3], na3.shape)

    assert_raise(Hdf5::H5Dataset::NotFound){file.dataset('/field/phi/00000')}  # Open a non-existent dataset
    assert_raise(Errno::ENOENT){Hdf5::H5File.new('test/fild.dat.h5')}  # Open a non-existent dataset
    assert_raise(Hdf5::H5File::InvalidFile){Hdf5::H5File.new('test/helper.rb')}  # Open a non-existent dataset

    file.close # Close the file
    
    
    file2 = Hdf5::H5File.new('test/omega.dat.h5')
    p file2.dataset('/omega').narray_all
    p ky = file2.dataset('/ky')
    p ky.narray_all
    assert_equal(-1, ky.dataspace.maxdims[0])
    ds = Hdf5::H5Dataspace.create_simple([12,1,1])
    p ds, ds.dims
    file2.close
  end
end
