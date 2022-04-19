*** Settings ***
Documentation      Orders robots from RobotSpareBin Industries Inc.
...                Saves the order HTML receipt as a PDF file.
...                Saves the screenshot of the ordered robot.
...                Embeds the screenshot of the robot to the PDF receipt.
...                Creates ZIP archive of the receipts and the images.

Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.Dialogs
Library           RPA.Robocloud.Secrets
Library           OperatingSystem
Library           RPA.PDF
Library           RPA.Archive
Library           Collections


*** Variables ***
${ORDER_URL}            https://robotsparebinindustries.com/#/robot-order

${IMG_DIR}         ${CURDIR}${/}img
${PDF_DIR}         ${CURDIR}${/}pdf

${INPUT_CSV}        ${CURDIR}${/}orders.csv
${OUTPUT_ZIP}       ${OUTPUT_DIR}${/}pdfs.zip
# ${INPUT_CSV_URL}    https://robotsparebinindustries.com/orders.csv

${OUTPUT_DIR}      ${CURDIR}${/}output


*** Test Cases ***
Order robots from RobotSpareBin Industries Inc
    Directory Cleanup

    Get The Joke From Vault
    ${USER_INPUT_CSV_URL}=    Get The Csv Url
    Open the robot order website

    ${orders}=    Get orders    ${USER_INPUT_CSV_URL}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form           ${row}
        Wait Until Keyword Succeeds     10x     2s    Preview the robot
        Wait Until Keyword Succeeds     10x     2s    Submit The Order
        ${orderid}  ${img_filename}=    Take a screenshot of the robot
        ${pdf_filename}=                Store the receipt as a PDF file    ORDER_NUMBER=${order_id}
        Embed the robot screenshot to the receipt PDF file     IMG_FILE=${img_filename}    PDF_FILE=${pdf_filename}
        Go to order another robot
    END
    Create a ZIP file of the receipts

    Log Out And Close The Browser

*** Keywords ***
Open the robot order website
    Open Available Browser     ${ORDER_URL}

Directory Cleanup
    Log To console      Cleaning up content from previous test runs

    Create Directory    ${OUTPUT_DIR}
    Create Directory    ${IMG_DIR}
    Create Directory    ${PDF_DIR}

Get orders
    [Arguments]     ${USER_INPUT_CSV_URL}
    Download    url=${USER_INPUT_CSV_URL}         target_file=${INPUT_CSV}    overwrite=True
    ${table}=   Read table from CSV    path=${INPUT_CSV}
    [Return]    ${table}

Close the annoying modal  
    Wait And Click Button           //*[@id="root"]/div/div[2]/div/div/div/div/div/button[2]

Fill the form
    [Arguments]     ${row}

    Set Local Variable      ${input_head}       //*[@id="head"]
    Set Local Variable      ${input_body}       body
    Set Local Variable      ${input_legs}       xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input
    Set Local Variable      ${input_address}    //*[@id="address"]
    Set Local Variable      ${btn_preview}      //*[@id="preview"]
    Set Local Variable      ${btn_order}        //*[@id="order"]
    Set Local Variable      ${img_preview}      //*[@id="robot-preview-image"]

    Wait Until Element Is Visible   ${input_head}
    Wait Until Element Is Enabled   ${input_head}
    Select From List By Value       ${input_head}           ${row}[Head]

    Wait Until Element Is Enabled   ${input_body}
    Select Radio Button             ${input_body}           ${row}[Body]

    Wait Until Element Is Enabled   ${input_legs}
    Input Text                      ${input_legs}           ${row}[Legs]
    Wait Until Element Is Enabled   ${input_address}
    Input Text                      ${input_address}        ${row}[Address]

Preview the robot
    Set Local Variable              ${btn_preview}      //*[@id="preview"]
    Set Local Variable              ${img_preview}      //*[@id="robot-preview-image"]
    Click Button                    ${btn_preview}
    Wait Until Element Is Visible   ${img_preview}

Submit the order
    Click button                    //*[@id="order"]
    Page Should Contain Element     //*[@id="receipt"]

Take a screenshot of the robot   
    Set Local Variable      ${img_robot}    //*[@id="robot-preview-image"]    

    Wait Until Element Is Visible   ${img_robot}
    Wait Until Element Is Visible   xpath://html/body/div/div/div[1]/div/div[1]/div/div/p[1]
  
    ${orderid}=                     Get Text            //*[@id="receipt"]/p[1]

    Set Local Variable              ${fully_qualified_img_filename}    ${IMG_DIR}${/}${orderid}.png

    Sleep   1sec
    Log To Console                  Capturing Screenshot to ${fully_qualified_img_filename}
    Capture Element Screenshot      ${img_robot}    ${fully_qualified_img_filename}
    
    [Return]    ${orderid}  ${fully_qualified_img_filename}

Go to order another robot     
    Click Button            //*[@id="order-another"]

Log Out And Close The Browser
    Close Browser

Create a Zip File of the Receipts
    Archive Folder With ZIP     ${PDF_DIR}  ${OUTPUT_ZIP}   recursive=True  include=*.pdf

Store the receipt as a PDF file
    [Arguments]        ${ORDER_NUMBER}

    Wait Until Element Is Visible   //*[@id="receipt"]
    Log To Console                  Printing ${ORDER_NUMBER}
    ${order_receipt_html}=          Get Element Attribute   //*[@id="receipt"]  outerHTML

    Set Local Variable              ${fully_qualified_pdf_filename}    ${PDF_DIR}${/}${ORDER_NUMBER}.pdf

    Html To Pdf                     content=${order_receipt_html}   output_path=${fully_qualified_pdf_filename}

    [Return]    ${fully_qualified_pdf_filename}

Embed the robot screenshot to the receipt PDF file
    [Arguments]     ${IMG_FILE}     ${PDF_FILE}

    Log To Console                  Printing Embedding image ${IMG_FILE} in pdf file ${PDF_FILE}

    Open PDF        ${PDF_FILE}

    @{myfiles}=       Create List     ${IMG_FILE}:x=0,y=0

    Add Files To PDF    ${myfiles}    ${PDF_FILE}     ${True}

    Close PDF           ${PDF_FILE}

Get The Joke From Vault
    ${secret}=              Get Secret      mysecrets
    Log                     Here is a joke for you: ${secret}[thejoke]   console=yes

Get The Csv Url
    Add heading             Where's the input?
    Add text input          url    label=What's the URL of the input CSV?     placeholder=https://robotsparebinindustries.com/orders.csv
    ${result}=              Run dialog
    [Return]                ${result.url}
