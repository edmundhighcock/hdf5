require 'helper'
require 'narray'

class TestHdf5 < Test::Unit::TestCase
  def test_read
    file = Hdf5::H5File.new('test/field.dat.h5')
    p file
    p file.is_hdf5?
    ds = file.dataset('/field/phi/0000000000')
    p ds.narray_type
     p dt = ds.datatype
     p dt.nmembers
     p dsp = ds.dataspace
     p dsp.ndims
     p dsp.dims
     p 'maxdims', dsp.maxdims
     p na = ds.narray_all
     assert_equal(Complex.rect(-0.05908707447771868, 0.0), na[0,0,0])
     p ['rv', file.close]
    file2 = Hdf5::H5File.new('test/omega.dat.h5')
    p file2.dataset('/omega').narray_all
    p ky = file2.dataset('/ky')
    p ky.narray_all
    assert_equal(-1, ky.dataspace.maxdims[0])
    ds = Hdf5::H5Dataspace.create_simple([12,1,1])
    p ds, ds.dims
  end
end
