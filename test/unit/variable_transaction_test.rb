require 'test_helper'
require 'variable_transaction'

class VariableTransactionTest < ActiveSupport::TestCase

  test "ActiveRecord revert" do
    extend VariableTransaction

    Item.delete_all
    assert_equal 0, Item.all.count
    bar = Item.new(:name => "foo")

    begin
      variable_transaction do
        Item.transaction do
          bar.name = "foobar"
          bar.save!
          raise IntentionalException.new("something happened within this transaction...")
        end
      end
    rescue IntentionalException => e
    end

    assert_equal 0, Item.all.count
    assert_equal true, bar.new_record?
    assert_nil bar.id
    assert_equal "foo", bar.name
  end

  test "ActiveRecord go through" do
    extend VariableTransaction

    Item.delete_all
    assert_equal 0, Item.all.count
    bar = Item.new(:name => "foo")

    begin
      variable_transaction do
        Item.transaction do
          bar.name = "foobar"
          bar.save!
        end
      end
    rescue Exception => e
      assert_fail_assertion "Shouldn't have raised an exception"
    end

    assert_equal false, bar.new_record?
    assert_not_nil bar.id
    assert_equal 1, Item.all.count
    assert_equal "foobar", bar.name
  end

  test "validation fail one record" do
    extend VariableTransaction

    Item.delete_all
    assert_equal 0, Item.all.count
    bar = Item.new #empty name will cause validation to fail

    begin
      variable_transaction do
        Item.transaction do
          bar.save!
        end
      end
    rescue Exception => e
      #...
    end

    assert_equal true, bar.new_record?
    assert_nil bar.id
    assert_equal 0, Item.all.count
    assert_nil bar.name
  end

  test "validation fail two record" do
    #As per https://rails.lighthouseapp.com/projects/8994/tickets/1948-transaction-block-sets-model-id-to-non-existent-row
    extend VariableTransaction

    Item.delete_all
    assert_equal 0, Item.all.count
    bar = Item.new #empty name will cause validation to fail
    foo = Item.new(:name => "foo")

    begin
      variable_transaction do
        Item.transaction do
          foo.save!
          bar.save!
        end
      end
    rescue Exception => e
      #...
    end

    assert_equal true, bar.new_record?
    assert_equal true, foo.new_record?
    assert_nil bar.id
    assert_nil foo.id
    assert_equal 0, Item.all.count
    assert_nil bar.name
    assert_equal "foo", foo.name
  end

  def test_simple_exception
    extend VariableTransaction

    begin
      a = 1
      b = 2
      variable_transaction do
        a = "foo"
        b = :bar
        raise IntentionalException.new("Testing")
      end
    rescue IntentionalException => e
      #... do some cleanup
    end
    assert_equal 1, a
    assert_equal 2, b
  end

  def test_simple_no_exception
    extend VariableTransaction

    begin
      a = 1
      b = 2
      variable_transaction do
        a = "foo"
        b = :bar
      end
    rescue Exception => e
      assert_fail_assertion "An exception shouldn't have been raised"
    end

    assert_equal "foo", a
    assert_equal :bar, b
  end

  def test_reference_exception
    extend VariableTransaction

    begin
      a = [1, 2, 3]
      b = [4, 5, 6]
      variable_transaction do
        a = ["foo", "bar"]
        b = [:foo, :bar]
        raise IntentionalException.new("Testing")
      end
    rescue IntentionalException => e
      #... do some cleanup
    end
    assert_equal [1, 2, 3], a
    assert_equal [4, 5, 6], b
  end

  def test_reference_no_exception
    extend VariableTransaction

    begin
      a = [1, 2, 3]
      b = [4, 5, 6]
      variable_transaction do
        a = ["foo", "bar"]
        b = [:foo, :bar]
      end
    rescue Exception => e
      assert_fail_assertion "An exception shouldn't have been raised"
    end
    assert_equal ["foo", "bar"], a
    assert_equal [:foo, :bar], b
  end
end

class IntentionalException < Exception
end
