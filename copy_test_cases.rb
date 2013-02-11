# Copyright 2002-2013 Rally Software Development Corp. All Rights Reserved.
#
# This script is open source and is provided on an as-is basis. Rally provides
# no official support for nor guarantee of the functionality, usability, or
# effectiveness of this code, nor its suitability for any application that
# an end-user might have in mind. Use at your own risk: user assumes any and
# all risk associated with use and implementation of this script in his or
# her own environment.

# Usage: ruby copy_test_cases.rb
# Specify the User-Defined variables below. Script will copy a list of Test Cases
# specified in the input CSV file, to new Test Cases within the same Test Folder
# and same Project

# Note: script does not copy TestCaseResults, assuming that the target hierarchy
# will be starting "fresh" from a testing perspective

require 'rally_api'
require 'csv'

$my_base_url       = "https://rally1.rallydev.com/slm"
$my_username       = "user@company.com"
$my_password       = "password"
$my_workspace      = "My Workspace"
$my_project        = "My Project"
$wsapi_version     = "1.40"
$filename          = "copy_test_cases.csv"


# Make no edits below this line!!
# =================================

#Setting custom headers
$headers                            = RallyAPI::CustomHttpHeader.new()
$headers.name                       = "Test Case Bulk Copy"
$headers.vendor                     = "Rally Labs"
$headers.version                    = "0.50"

# Load (and maybe override with) my personal/private variables from a file...
my_vars= File.dirname(__FILE__) + "/my_vars.rb"
if FileTest.exist?( my_vars ) then require my_vars end

def copy_test_steps(source_test_case, target_test_case)

  source_test_case_steps = source_test_case["Steps"]

  source_test_case_steps.each do |source_test_case_step|
    full_source_step = source_test_case_step.read
    target_step_fields = {}
    target_step_fields["TestCase"] = target_test_case
    target_step_fields["StepIndex"] = full_source_step["StepIndex"]
    target_step_fields["Input"] = full_source_step["Input"]
    target_step_fields["ExpectedResult"] = full_source_step["ExpectedResult"]
    begin
      target_test_case_step = @rally.create(:testcasestep, target_step_fields)
      puts "===> Copied TestCaseStep: #{target_test_case_step["_ref"]}"
    rescue => ex
      puts "Test Case Step not copied due to error:"
      puts ex
    end
  end

end

def copy_attachments(source_test_case, target_test_case)
  source_attachments = source_test_case["Attachments"]

  source_attachments.each do |source_attachment|
    full_source_attachment = source_attachment.read
    source_attachment_content = full_source_attachment["Content"]
    full_source_attachment_content = source_attachment_content.read

    # Create AttachmentContent Object for Target
    target_attachment_content_fields = {}
    target_attachment_content_fields["Content"] = full_source_attachment_content["Content"]
    begin
      target_attachment_content = @rally.create(:attachmentcontent, target_attachment_content_fields)
      puts "===> Copied AttachmentContent: #{target_attachment_content["_ref"]}"
    rescue => ex
      puts "AttachmentContent not copied due to error:"
      puts ex
    end

    # Now Create Attachment Container
    target_attachment_fields = {}
    target_attachment_fields["Name"] = "(Copy of) " + full_source_attachment["Name"]
    target_attachment_fields["Description"] = full_source_attachment["Description"]
    target_attachment_fields["Content"] = target_attachment_content
    target_attachment_fields["ContentType"] = full_source_attachment["ContentType"]
    target_attachment_fields["Size"] = full_source_attachment["Size"]
    target_attachment_fields["Artifact"] = target_test_case
    target_attachment_fields["User"] = full_source_attachment["User"]
    begin
      target_attachment = @rally.create(:attachment, target_attachment_fields)
      puts "===> Copied Attachment: #{target_attachment["_ref"]}"
    rescue => ex
      puts "Attachment not copied due to error:"
      puts ex
    end
  end
end

def get_test_case_fields(source_test_case)

  # Check if there's an Owner
  if !source_test_case["Owner"].nil?
    source_owner = source_test_case["Owner"]
  else
    source_owner = nil
  end

  # Populate field data from Source to Target
  target_fields = {}
  target_fields["Package"] = source_test_case["Package"]
  target_fields["Description"] = source_test_case["Description"]
  target_fields["Method"] = source_test_case["Method"]
  target_fields["Name"] = source_test_case["Name"]
  target_fields["Objective"] = source_test_case["Objective"]
  target_fields["Owner"] = source_owner
  target_fields["PostConditions"] = source_test_case["PostConditions"]
  target_fields["PreConditions"] = source_test_case["PreConditions"]
  target_fields["Priority"] = source_test_case["Priority"]
  target_fields["Project"] = source_test_case["Project"]
  target_fields["Risk"] = source_test_case["Risk"]
  target_fields["ValidationInput"] = source_test_case["ValidationInput"]
  target_fields["ValidationExpectedResult"] = source_test_case["ValidationExpectedResult"]
  target_fields["Tags"] = source_test_case["Tags"]
  target_fields["TestFolder"] = source_test_case["TestFolder"]

  return target_fields

end

def copy_test_case(header,row)

  test_case_formatted_id                   = row[header[0]].strip

  # Lookup test case to move
  test_case_query = RallyAPI::RallyQuery.new()
  test_case_query.type = :testcase
  test_case_query.fetch = "FormattedID,ObjectID,TestFolder,Project,Name"
  test_case_query.query_string = "(FormattedID = \"" + test_case_formatted_id + "\")"

  test_case_query_result = @rally.find(test_case_query)

  if test_case_query_result.total_result_count == 0
    puts "Test Case #{test_case_formatted_id} not found...skipping"
  else

    source_test_case = test_case_query_result.first

    # Get full object for Source Test Case
    full_source_test_case = source_test_case.read

    # Populate data field values of target test case
    target_test_case_fields = get_test_case_fields(full_source_test_case)

    # Create the Target Test Case
    begin
      target_test_case = @rally.create(:testcase, target_test_case_fields)
      puts "Test Case: #{full_source_test_case["FormattedID"]} successfully copied to #{target_test_case["FormattedID"]}"
    rescue => ex
      puts "Test Case: #{full_source_test_case["FormattedID"]} not copied due to error"
      puts ex
    end

    # Now Copy Test Steps
    copy_test_steps(full_source_test_case, target_test_case)

    # Now Copy Attachments
    copy_attachments(full_source_test_case, target_test_case)

  end

end

begin
  #==================== Make a connection to Rally ====================
  config                  = {:base_url => $my_base_url}
  config[:username]       = $my_username
  config[:password]       = $my_password
  config[:workspace]      = $my_workspace
  config[:project]        = $my_project
  config[:version]        = $wsapi_version
  config[:headers]        = $headers

  @rally = RallyAPI::RallyRestJson.new(config)

  input  = CSV.read($filename)

  header = input.first #ignores first line

  rows   = []
  (1...input.size).each { |i| rows << CSV::Row.new(header, input[i]) }

  rows.each do |row|
    copy_test_case(header, row)
  end

end