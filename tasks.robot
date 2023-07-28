*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library    RPA.Browser.Selenium
Library    RPA.HTTP
Library    RPA.PDF
Library    RPA.Archive

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Close the annoying modal
    # Download the order files
    ${order_data}=    Get orders

    # Loop through the orders and fill in the form
    FOR    ${order}    IN    @{order_data}
        Close the annoying modal
        Fill the from   ${order}
    END

    Zip the PDF files

*** Keywords ***
Open the robot order website
    #ToDo: Implement your keyword here
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Get orders
    #ToDo: Implement your keyword here
    ${response}=    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    Should Be Equal As Strings         ${response.status_code}    200
    ${csv_content}=    Set Variable    ${response.text}
    ${order_data}=     Evaluate    list(csv.DictReader(${csv_content.splitlines()}))
    [Return]    ${order_data}

Fill the from
    [Arguments]    ${order}
    Select From List By Index    id=head    ${order["Head"]}
    Click Element When Visible    id=id-body-${order["Body"]}
    Input Text    xpath=//label[contains(text(), '3. Legs')]/following-sibling::input    ${order["Legs"]}
    Input Text    id=address    ${order["Address"]}
    Click Button    id=preview
    Click Button until invisible   id=order
    Embed the robot screenshot to the receipt PDF file    ${order}[Order number]
    Click Button    id=order-another

Close the annoying modal
    Click Element If Visible    xpath=//button[text()="OK"]


Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${order_number}
    ${receipt_html}=    Get Element Attribute    id=receipt    innerhtml
    ${preview_html}=    Get Element Attribute    id=robot-preview-image    innerhtml
    ${pdf_content}=    Catenate    ${receipt_html}    ${preview_html}
    Html To Pdf    ${pdf_content}    ${OUTPUT_DIR}${/}PDFs/${order_number}_Receipt_Preview.pdf

Click Button until invisible
    [Arguments]    ${locator}
    ${is_visible}=    Is Element Visible    ${locator}
    WHILE    ${is_visible} == True
        Click Button    ${locator}
        ${is_visible}=    Is Element Visible    ${locator}
    END

Zip the PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip    ${OUTPUT_DIR}${/}PDFs    ${zip_file_name}