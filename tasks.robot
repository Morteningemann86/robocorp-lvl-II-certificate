*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    #auto_close=${False}
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Desktop
Library           RPA.Archive    # Allows you to zip files and folders
Library           Dialogs    # Allows you make dialog boxes
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault
Library           Process

*** Keywords ***
Get secret from vault
    #TODO: setup up the Control Room Vault
    ${secret}=    Get Secret    Secret_url
    log    ${secret}[url]

Ask user for input on CSV-file path
    Add text input    url    label=URL for CSV-file
    ${response}=    run dialog    height=300    width=700    # Input the following: https://robotsparebinindustries.com/orders.csv
    [Return]    ${response.url}

Open the robot order website
    ${secret}=    Get Secret    Secret_url
    Open Available Browser    ${secret}[url]    # https://robotsparebinindustries.com/#/robot-order
    Log    ${secret}[url]

Get orders
    [Arguments]    ${url}
    Download    ${url}    overwrite=True    # https://robotsparebinindustries.com/orders.csv
    ${orders}    Read table from CSV    orders.csv    header=True
    [Return]    ${orders}

Close the annoying modal
    Click Element If Visible    css:button.btn.btn-dark

Fill the form
    [Arguments]    ${row}
    Wait Until Element Is Visible    id=head
    #Select From List By Label    id=head    Peanut crusher head
    Select From List By Value    id=head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${row}[Legs]    # Because the ID and NAME selectors are changing name for each reload, we use the PLACEHOLDER selector instead
    Input Text    id=address    ${row}[Address]

Preview the robot
    Click Element    id=preview
    Click Element When Visible    id=robot-preview-image    # This step makes sure that the element is fully loaded before taking the screenshot
    Capture Element Screenshot    id=robot-preview-image

Submit the order
    Click Button    id=order
    ${Status} =    Run Keyword And Return Status    Submit the order    # This evaluates a Boolean on whether id=order has been succesfully clicked
    Run Keyword if    ${Status} == 'False'    Submit the order

Store the receipt as a PDF file
    [Arguments]    ${row}
    Wait Until Element Is Visible    id=receipt    timeout=10 second
    ${pdf}    Capture Element Screenshot    id=receipt    ${OUTPUTDIR}/receipts/id_image_id-${row}.png
    [Return]    ${pdf}

Go to order another robot
    Click Element    id=order-another

Take a screenshot of the robot
    [Arguments]    ${row}
    Wait Until Element Is Visible    id=robot-preview-image
    ${pdf}    Capture Element Screenshot    id=robot-preview-image    ${OUTPUTDIR}/receipts/id_image_id-bot-preview-${row}.png
    [Return]    ${pdf}

 Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}    ${row}
    ${pdf-combined}=    Create List    ${pdf}    ${screenshot}
    Add Files To Pdf    ${pdf-combined}    ${OUTPUTDIR}/receipts/Purchase_order${row}.pdf

Create a ZIP file of the receipts
    #how to zip
    Archive Folder With Zip    ${OUTPUTDIR}/receipts    all_purchases.zip

Log out and close browser
    Close Browser

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Get secret from vault
    ${url}=    Ask user for input on CSV-file path
    Open the robot order website
    ${orders}    Get orders    ${url}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}    ${row}[Order number]
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Log out and close browser
#    Terminate All Processes
