require File.dirname(__FILE__) + '/../test_helper'

class ImportsControllerTest < ActionController::TestCase
  def setup
    # runs before every test
    login
  end
  
  def test_should_create_import
    assert_difference('Import.count') do
      post :create_vcard, {:upload => { :file =>
            fixture_file_upload("files/vCards.vcf", "text/x-vcard"),
          :file_temp => '' }}
    end
    # FIXME: assert redirect for correct locations e.g.
    # assert_redirected_to import_path(assigns(:import))
    assert_response :redirect
  end

  def test_should_verify_import
 
  end
  
#  def test_should_show_import
#    get :show, :id => imports(:one).id
#    assert_response :success
#  end
#
#  def test_should_get_edit
#    get :edit, :id => imports(:one).id
#    assert_response :success
#  end
#
#  def test_should_update_import
#    put :update, :id => imports(:one).id, :import => { }
#    assert_redirected_to import_path(assigns(:import))
#  end
#
#  def test_should_destroy_import
#    assert_difference('Import.count', -1) do
#      delete :destroy, :id => imports(:one).id
#    end
#
#    assert_redirected_to imports_path
#  end
  
end
