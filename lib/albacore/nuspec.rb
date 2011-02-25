require 'albacore/albacoretask'
require 'rexml/document'

class NuspecFile
  def initialize(src, target) 
    @src = src
    @target = target 
  end
  
  def render(xml) 
    depend = xml.add_element 'file', { 'src' => @src }
    
    depend.add_attribute( 'target', @target ) if @target.to_s == 0
  end
end

class NuspecDependency

  attr_accessor :id, :version

  def initialize(id, version)
    @id = id
    @version = version
  end
  
  def render( xml )
    depend = xml.add_element 'dependency', {'id' => @id, 'version' => @version}
  end
end

class Nuspec
  include Albacore::Task
  
  attr_accessor :id, :version, :authors, :description, :language, :licenseUrl, :projectUrl, :output_file,
                :owners, :summary, :iconUrl, :requireLicenseAcceptance, :tags, :working_directory
				
  def initialize()
	@dependencies = Array.new
	@files = Array.new
    super()
  end

  def dependency(id, version)
    @dependencies.push NuspecDependency.new(id, version)
  end
  
  def file(src, target=nil)
    @files.push NuspecFile.new(src, target)
  end
  
  def execute
    valid = check_output_file @output_file
    check_required_field(@id, "id")
    check_required_field(@version, "version")
    check_required_field(@authors, "authors")
    check_required_field(@description, "description")
    
    if(! @working_directory.nil?)
      @working_output_file = File.join(@working_directory, @output_file)
    else
      @working_output_file = @output_file
    end

    builder =  Document.new
    build(builder)
    output=""
    builder.write(output)

    File.open(@working_output_file, 'w') {|f| f.write(output) }
  end

  def build(document)
    package = document.add_element('package')
    metadata = package.add_element('metadata')
    metadata.add_element('id').add_text(@id)
    metadata.add_element('version').add_text(@version)
    metadata.add_element('authors').add_text(@authors)
    metadata.add_element('description').add_text(@description)
    metadata.add_element('language').add_text(@language) if !@language.nil?
    metadata.add_element('licenseUrl').add_text(@licenseUrl) if !@licenseUrl.nil?
    metadata.add_element('projectUrl').add_text(@projectUrl) if !@projectUrl.nil?
    metadata.add_element('owners').add_text(@owners) if !@owners.nil?
    metadata.add_element('summary').add_text(@summary) if !@summary.nil?
    metadata.add_element('iconUrl').add_text(@iconUrl) if !@iconUrl.nil?
    metadata.add_element('requireLicenseAcceptance').add_text(@requireLicenseAcceptance) if !@requireLicenseAcceptance.nil?
    metadata.add_element('tags').add_text(@tags) if !@tags.nil?

    if @dependencies.length > 0
      depend = metadata.add_element('dependencies')
      @dependencies.each {|x| x.render(depend)}
    end

    if @files.length > 0
      files = package.add_element('files')
      @files.each {|x| x.render(files)}
    end
  end

  def check_output_file(file)
    return true if file
    fail_with_message 'output_file cannot be nil'
    return false
  end

  def check_required_field(field, fieldname)
    return true if !field.nil?
    raise "Nuget: required field '#{fieldname}' is not defined"
  end
end
