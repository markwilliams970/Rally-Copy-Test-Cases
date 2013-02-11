Rally-Copy-Test-Cases
=====================

- Configuring and Using the Copy Test Cases

- Create directory for script and associated files:

- C:\Users\username\Documents\Rally Copy Test Cases\ 

- Download the copy_test_cases.rb script and the copy_test_cases.csv file to the above directory
 

- Create your Test Case file. It must be a plain text CSV file with a simple one-column format:
<pre>
	Test Case FormattedID
	TC327
	TC328
	TC329
</pre>
- The script will make a copy of each Test Case listed in the CSV file. If the script lookup against Rally for Test Case Formatted ID in the first column fails to find the source Test Case, it will skip that row and move on.

- Using a text editor, customize the code parameters in the my_vars.rb file for your environment.
 <pre>
	my_vars.rb:
	
	$my_base_url                     = "https://rally1.rallydev.com/slm"
	$my_username                     = "user@company.com"
	$my_password                     = "topsecret"
	$my_workspace                    = "My Workspace"
	$my_project                      = "My Project"
	$wsapi_version                   = "1.40"
	$filename                        = "copy_test_cases.csv"
</pre>

- Run the script.
<pre>
C:\> ruby copy_test_cases.rb

	Test Case: TC327 successfully copied to TC470
	Test Case: TC328 successfully copied to TC471
	Test Case: TC329 successfully copied to TC472
</pre>

The script will copy Test Cases, including Steps, Attachments, and Tags. The script does _not_ associate the Test Cases to a Work Product (i.e. Story or Defect, and also does not copy any Test Case Results).

Please Note: This will make copies of ALL Test Cases listed in the copy_test_cases.csv file. Please be CAUTIOUS WHEN USING THIS SCRIPT.
