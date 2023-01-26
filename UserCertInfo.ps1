#Если скрипт будет использователься регулярно с помощью shedule то для начала неободимо удалить устаревшие файлы
#Предположим что это путь к папке где лежат все отчёты
$TargetFolder = "C:\Script_answer\All_User_Cert_INFO\" 
#Указываем период хранения файлов
$Period = "-3" 
#Получаем крайнюю дату хранения файлов
$ChDaysDel = (Get-Date).AddDays($Period)
#Удаляем все файлы с датой создания больше ChDaysDel
GCI -Path $TargetFolder -Recurse | Where-Object {$_.CreationTime -LT $ChDaysDel} | RI -Recurse -Force 
#-----------------------------------------------------------------------------------------------------

#Выгружаем из AD информацию обо всех сотрудниках
$AD_users = Get-ADUser -SearchBase "OU=Employees, DC=YourDomain, DC=com" -Filter '*' -Properties certificates, extensionattribute11, extensionattribute12, extensionattribute13, department

#Создаём пустой список для информации о сертификатах пользователей
$All_user_cert_info = @()

#Проходимся по всем сотрудникам
ForEach ($user in $AD_users)
{
        #Если в extensionattribute11, extensionattribute12, extensionattribute13 записано ФИО, то складываем его в строку
        $FIO = $user.extensionattribute11 + " " + $user.extensionattribute12 + " " + $user.extensionattribute13

        #Получаем информацию о сертификате пользователя, а конкретно о дате начала действия сертификата и дате окончания
        $cert_info = $user.certificates | foreach {New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $_} | select NotBefore, NotAfter 

        #Преобразование полученной информации в табличный вид
        $user_cert_info = @{
            "Отдел пользователя" = [string]$user.department;
            "ФИО" = [string]$FIO
            "Имя входа пользователя" = [string]$user.SamAccountName; 
            "Дата начала действия сертификата" = ([string]$cert_info.NotBefore).split(' ')[0];
            "Дата окончания действия сертификата" = ([string]$cert_info.NotAfter).split(' ')[0];
        }

        #Запись полученых данных в общую переменную
        $All_user_cert_info += [pscustomobject]$user_cert_info 
}

#Преобразование полученной информации в CSV файл
$All_user_cert_info | Export-Csv C:\Script_answer\All_User_Cert_INFO\$((Get-Date).ToString('dd-MM-yyyy')).csv -notype -UseCulture -Encoding UTF8