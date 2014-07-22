require 'helper'
require 'narray'

class TestHdf5 < Test::Unit::TestCase
  def test_read
    file = H5SimpleReader::H5File.new('test/field.dat.h5')
    p file
    p file.is_hdf5?
    ds = file.dataset('/field/phi/0000000000')
    p ds.narray_type
     p dt = ds.datatype
     p dt.nmembers
     p dsp = ds.dataspace
     p dsp.ndims
     p dsp.dims
     p ds.narray_all
     p ['rv', file.close]
  end
end
