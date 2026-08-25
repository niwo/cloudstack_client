require "test_helper"

describe CloudstackClient::Utils do
  let(:utils) { Object.new.extend(CloudstackClient::Utils) }

  describe "camel_case_to_underscore" do
    it "converts a simple camel case command" do
      _(utils.camel_case_to_underscore("listVirtualMachines"))
        .must_equal "list_virtual_machines"
    end

    it "splits a leading acronym from the following word" do
      _(utils.camel_case_to_underscore("listVPCOfferings"))
        .must_equal "list_vpc_offerings"
    end

    it "handles a trailing acronym" do
      _(utils.camel_case_to_underscore("listOsTypes")).must_equal "list_os_types"
    end

    it "handles consecutive capitals followed by a word" do
      _(utils.camel_case_to_underscore("createSSHKeyPair"))
        .must_equal "create_ssh_key_pair"
    end

    it "converts hyphens to underscores" do
      _(utils.camel_case_to_underscore("some-command")).must_equal "some_command"
    end

    it "leaves an already underscored name unchanged" do
      _(utils.camel_case_to_underscore("list_apis")).must_equal "list_apis"
    end
  end

  describe "underscore_to_camel_case" do
    it "converts an underscored name" do
      _(utils.underscore_to_camel_case("list_virtual_machines"))
        .must_equal "listVirtualMachines"
    end

    it "returns a name without underscores unchanged" do
      _(utils.underscore_to_camel_case("listApis")).must_equal "listApis"
    end

    it "cannot restore acronym casing, because the conversion is lossy" do
      # Documents a known limitation: "ssh" carries no record of "SSH".
      # Api resolves underscored names through an index instead of relying
      # on this method being a true inverse.
      _(utils.underscore_to_camel_case("create_ssh_key_pair"))
        .must_equal "createSshKeyPair"
    end
  end

  describe "round tripping real command names" do
    it "round trips names without acronyms" do
      %w[listVirtualMachines deployVirtualMachine listOsTypes listApis].each do |name|
        underscored = utils.camel_case_to_underscore(name)
        _(utils.underscore_to_camel_case(underscored)).must_equal name
      end
    end
  end
end
