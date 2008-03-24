require File.dirname(__FILE__) + '/base'

describe Rush::Access do
	before do
		@access = Rush::Access.new
	end

	it "has roles: user, group, other" do
		@access.class.roles == %w(user group other)
	end

	it "has permissions: read, write, execute" do
		@access.class.permissions == %w(read write execute)
	end

	it "gets parts from a one-part symbol like :user" do
		@access.parts_from(:user).should == %w(user)
	end

	it "gets parts from a two-part symbol like :read_write" do
		@access.parts_from(:read_write).should == %w(read write)
	end

	it "allows use of 'and' in multipart symbols, like :user_and_group" do
		@access.parts_from(:user_and_group).should == %w(user group)
	end

	it "extract_list verifies that all the parts among the valid choices" do
		@access.should_receive(:parts_from).with(:red_green).and_return(%w(red green))
		@access.extract_list('type', :red_green, %w(red blue green)).should == %w(red green)
	end

	it "extract_list raises a BadAccessSpecifier when there is part not in the list of choices" do
		lambda do
			@access.extract_list('role', :user_bork, %w(user group))
		end.should raise_error(Rush::BadAccessSpecifier, "Unrecognized role: bork")
	end

	it "sets one value in the matrix of permissions and roles" do
		@access.set_matrix(%w(read), %w(user))
		@access.user_read.should == true
	end

	it "sets two values in the matrix of permissions and roles" do
		@access.set_matrix(%w(read), %w(user group))
		@access.user_read.should == true
		@access.group_read.should == true
	end

	it "sets four values in the matrix of permissions and roles" do
		@access.set_matrix(%w(read write), %w(user group))
		@access.user_read.should == true
		@access.group_read.should == true
		@access.user_write.should == true
		@access.group_write.should == true
	end

	it "parse options hash" do
		@access.parse(:read => :user)
		@access.user_read.should == true
	end

	it "generates octal permissions from its member vars" do
		@access.user_read = true
		@access.octal_permissions.should == 0400
	end

	it "generates octal permissions from its member vars" do
		@access.user_read = true
		@access.user_write = true
		@access.user_execute = true
		@access.group_read = true
		@access.group_execute = true
		@access.octal_permissions.should == 0750
	end

	it "applies its settings to a file" do
		file = "/tmp/rush_spec_#{Process.pid}"
		begin
			system "rm -rf #{file}; touch #{file}; chmod 770 #{file}"
			@access.user_read = true
			@access.apply(file)
			`ls -l #{file}`.should match(/^-r--------/)
		ensure
			system "rm -rf #{file}; touch #{file}"
		end
	end

	it "serializes itself to a hash" do
		@access.user_read = true
		@access.to_hash.should == {
			:user_read => 1, :user_write => 0, :user_execute => 0,
			:group_read => 0, :group_write => 0, :group_execute => 0,
			:other_read => 0, :other_write => 0, :other_execute => 0,
		}
	end

	it "unserializes from a hash" do
		@access.from_hash(:user_read => '1')
		@access.user_read.should == true
	end

	it "initializes from a serialized hash" do
		@access.class.should_receive(:new).and_return(@access)
		@access.class.from_hash(:user_read => '1').should == @access
		@access.user_read.should == true
	end

	it "initializes from a parsed options hash" do
		@access.class.should_receive(:new).and_return(@access)
		@access.class.parse(:read => :user_group).should == @access
		@access.user_read.should == true
	end
end
