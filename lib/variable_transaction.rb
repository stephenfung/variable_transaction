module VariableTransaction
  def variable_transaction(&block)
    #Similar to a database transaction, but if there's an exception thrown in the block passed in, revert the changes to
    #the local variables in the block's binding (i.e. typically the local variables of the caller) to their original values.

    #We need to do deep copying, so dup() and clone() won't work (unless we implement deep-copying semantics for them)
    #This implementation saves the original values using Marshal.dump and restores them using Marshal.load.
    #This will not work for objects that are not serializable.

    successful = false
    original_values = eval "local_variables.select { |l| l != '_' }.inject({}) { |h, l| h[l] = Marshal.dump(eval l.to_s); h }", block.binding
    begin
      yield
      successful = true
    ensure
      unless successful
        original_values.each do |key, value|
          eval("lambda { |v| #{key} = v }", block.binding).call(Marshal.load(value))
        end
      end
    end
  end
end
