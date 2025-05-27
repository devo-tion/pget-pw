Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName System.Xaml

# Load icon
$iconPath = Join-Path $PSScriptRoot "pget-pw.ico"
$icon = New-Object System.Windows.Media.Imaging.BitmapImage
$icon.BeginInit()
$icon.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
$icon.UriSource = New-Object System.Uri($iconPath)
$icon.EndInit()

# Load JSON
$appsConfig = Get-Content -Raw -Path ".\apps.json" | ConvertFrom-Json #!important !fetch config from local files for testing purpose.
#$appsUrl = "https://raw.githubusercontent.com/devo-tion/pget-pw/refs/heads/main/apps.json"
#$apps = Invoke-RestMethod -Uri $appsUrl

# Load tweaks from JSON
$tweaksConfig = Get-Content -Raw -Path ".\tweaks.json" | ConvertFrom-Json
$tweaks = $tweaksConfig.tweaks

# Group tweaks by category
$tweakCategories = @{}
foreach ($tweak in $tweaks) {
    $category = if ($tweak.category) { $tweak.category } else { "General" }
    if (-not $tweakCategories.ContainsKey($category)) {
        $tweakCategories[$category] = New-Object System.Collections.ArrayList
    }
    $tweakCategories[$category].Add($tweak)
}

# Define static XAML with a placeholder StackPanel
$xaml = @"
<Window 
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="pget-pw - Easy windows apps and configurations toolbox" WindowState="Normal" ResizeMode="NoResize"
    Background="#1e1e1e" FontFamily="Segoe UI" Foreground="White">

    <Window.Resources>
        <!-- Global Styles -->
        <Style TargetType="Button">
            <Setter Property="Background" Value="#0078D7"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Padding" Value="8,4"/>
            <Setter Property="Margin" Value="0,5,0,5"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="6">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#252526"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderBrush" Value="#3a3a3a"/>
            <Setter Property="Padding" Value="4"/>
        </Style>

        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Margin" Value="4"/>
        </Style>

        <Style TargetType="ProgressBar">
            <Setter Property="Height" Value="20"/>
            <Setter Property="Foreground" Value="#0078D7"/>
            <Setter Property="Background" Value="#3a3a3a"/>
        </Style>

        <Style TargetType="TabItem">
            <Setter Property="Background" Value="#2d2d2d"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TabItem">
                        <Border Name="Border" Background="{TemplateBinding Background}" BorderBrush="#3a3a3a" BorderThickness="1,1,1,0" CornerRadius="6,6,0,0">
                            <ContentPresenter x:Name="ContentSite" VerticalAlignment="Center" HorizontalAlignment="Center" ContentSource="Header" Margin="10,5"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter Property="Background" Value="#0078D7"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="TabControl">
            <Setter Property="Background" Value="#1e1e1e"/>
            <Setter Property="BorderBrush" Value="#3a3a3a"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Margin" Value="0,0,0,10"/>
        </Style>

        <!-- Style for toggle switch -->
        <Style x:Key="ToggleSwitchStyle" TargetType="ToggleButton">
            <Setter Property="Width" Value="40"/>
            <Setter Property="Height" Value="20"/>
            <Setter Property="Background" Value="#3a3a3a"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ToggleButton">
                        <Border x:Name="Border" Background="{TemplateBinding Background}" CornerRadius="10">
                            <Grid>
                                <Ellipse x:Name="Dot" Width="16" Height="16" Fill="White" HorizontalAlignment="Left" Margin="2,0,0,0"/>
                            </Grid>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter Property="Background" Value="#0078D7"/>
                                <Setter TargetName="Dot" Property="HorizontalAlignment" Value="Right"/>
                                <Setter TargetName="Dot" Property="Margin" Value="0,0,2,0"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Style for application items -->
        <Style x:Key="AppItemStyle" TargetType="Border">
            <Setter Property="Background" Value="#252526"/>
            <Setter Property="BorderBrush" Value="#3a3a3a"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="CornerRadius" Value="4"/>
            <Setter Property="Margin" Value="0,5,0,5"/>
            <Setter Property="Padding" Value="10"/>
        </Style>
    </Window.Resources>

    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <TabControl Grid.Row="0">
            <TabItem Header="Applications">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <StackPanel Grid.Row="0" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,0,0,10">
                        <Button Name="selectAllBtn" Content="Select All" Margin="0,0,5,0"/>
                        <Button Name="uncheckAllBtn" Content="Uncheck All" Margin="0,0,5,0"/>
                    </StackPanel>

                    <ScrollViewer Grid.Row="1">
                        <StackPanel Name="programList" Margin="5"/>
                    </ScrollViewer>

                    <StackPanel Grid.Row="2">
                        <ProgressBar Name="progressBar" Margin="0,10,0,10" Minimum="0" Maximum="100"/>
                        <Button Name="installBtn" Content="Install Selected"/>
                        <TextBox Name="logBox" Height="100" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto"/>
                    </StackPanel>
                </Grid>
            </TabItem>

            <TabItem Header="Tweaks">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <StackPanel Grid.Row="0" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,0,0,10">
                        <Button Name="selectAllFavBtn" Content="Select All" Margin="0,0,5,0"/>
                        <Button Name="uncheckAllFavBtn" Content="Uncheck All" Margin="0,0,5,0"/>
                    </StackPanel>

                    <ScrollViewer Grid.Row="1">
                        <StackPanel Name="favoritesList" Margin="5"/>
                    </ScrollViewer>

                    <StackPanel Grid.Row="2">
                        <ProgressBar Name="progressBarTweaks" Margin="0,10,0,10" Minimum="0" Maximum="100"/>
                        <Button Name="installTweaksBtn" Content="Install Selected"/>
                        <TextBox Name="logBoxTweaks" Height="100" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto"/>
                    </StackPanel>
                </Grid>
            </TabItem>

            <TabItem Header="Repair">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <StackPanel Grid.Row="0" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,0,0,10">
                        <Button Name="selectAllRepairBtn" Content="Select All" Margin="0,0,5,0"/>
                        <Button Name="uncheckAllRepairBtn" Content="Uncheck All" Margin="0,0,5,0"/>
                    </StackPanel>

                    <ScrollViewer Grid.Row="1">
                        <StackPanel Name="repairList" Margin="5"/>
                    </ScrollViewer>

                    <StackPanel Grid.Row="2">
                        <ProgressBar Name="progressBarRepair" Margin="0,10,0,10" Minimum="0" Maximum="100"/>
                        <Button Name="installRepairBtn" Content="Run Selected"/>
                        <TextBox Name="logBoxRepair" Height="100" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto"/>
                    </StackPanel>
                </Grid>
            </TabItem>

            <TabItem Header="About">
                <StackPanel>
                    <TextBlock Text="Pget-pw is a PowerShell script that installs applications using winget."/>
                    <TextBlock Text="Version 1"/>
                    <TextBlock Text="Author: devo-tion"/>
                </StackPanel>
            </TabItem>
        </TabControl>
    </Grid>
</Window>
"@

# Parse XAML into Window object
[xml]$xamlXml = $xaml
$reader = New-Object System.Xml.XmlNodeReader $xamlXml
$window = [Windows.Markup.XamlReader]::Load($reader)

# Set window icon
$window.Icon = $icon

# Get elements
$programList = $window.FindName("programList")
$installBtn = $window.FindName("installBtn")
$selectAllBtn = $window.FindName("selectAllBtn")
$uncheckAllBtn = $window.FindName("uncheckAllBtn")
$progressBar = $window.FindName("progressBar")
$logBox = $window.FindName("logBox")

# Get Tweaks tab elements
$favoritesList = $window.FindName("favoritesList")
$installTweaksBtn = $window.FindName("installTweaksBtn")
$selectAllFavBtn = $window.FindName("selectAllFavBtn")
$uncheckAllFavBtn = $window.FindName("uncheckAllFavBtn")
$progressBarTweaks = $window.FindName("progressBarTweaks")
$logBoxTweaks = $window.FindName("logBoxTweaks")

# Get Repair tab elements
$repairList = $window.FindName("repairList")
$installRepairBtn = $window.FindName("installRepairBtn")
$selectAllRepairBtn = $window.FindName("selectAllRepairBtn")
$uncheckAllRepairBtn = $window.FindName("uncheckAllRepairBtn")
$progressBarRepair = $window.FindName("progressBarRepair")
$logBoxRepair = $window.FindName("logBoxRepair")

# Store checkboxes for later reference
$checkboxes = @{}
$tweakCheckboxes = @{}
$repairCheckboxes = @{}

# Function to create an application item
function New-AppItem {
    param (
        [string]$Name,
        [string]$Description,
        [string]$PackageIdentifier,
        [string[]]$Links,
        [string]$Category
    )
    
    $border = New-Object System.Windows.Controls.Border
    $border.Style = $window.FindResource("AppItemStyle")
    $border.Margin = "5"
    $border.MinWidth = 200
    $border.MaxWidth = 300
    $border.Height = 120
    
    $grid = New-Object System.Windows.Controls.Grid
    $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height = "Auto" }))
    $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height = "*" }))
    
    $topPanel = New-Object System.Windows.Controls.StackPanel
    $topPanel.Orientation = "Horizontal"
    $topPanel.Margin = "0,0,0,5"
    
    $checkbox = New-Object System.Windows.Controls.CheckBox
    $checkbox.Margin = "0,0,10,0"
    $checkbox.VerticalAlignment = "Center"
    
    $nameText = New-Object System.Windows.Controls.TextBlock
    $nameText.Text = $Name
    $nameText.FontWeight = "SemiBold"
    $nameText.VerticalAlignment = "Center"
    $nameText.TextWrapping = "Wrap"
    
    $topPanel.Children.Add($checkbox)
    $topPanel.Children.Add($nameText)
    
    $grid.Children.Add($topPanel)
    
    $descText = New-Object System.Windows.Controls.TextBlock
    $descText.TextWrapping = "Wrap"
    $descText.Foreground = "#AAAAAA"
    $descText.MaxHeight = 60
    $descText.TextTrimming = "CharacterEllipsis"
    $descText.SetValue([System.Windows.Controls.Grid]::RowProperty, 1)
    
    # Split description by links and create text with hyperlinks
    $inlines = New-Object System.Collections.Generic.List[Windows.Documents.Inline]
    $parts = $Description -split '\[([^\]]+)\]\(([^\)]+)\)'
    
    for ($i = 0; $i -lt $parts.Length; $i++) {
        if ($i % 3 -eq 0) {
            # Regular text
            $run = New-Object Windows.Documents.Run
            $run.Text = $parts[$i]
            $inlines.Add($run)
        }
        elseif ($i % 3 -eq 1) {
            # Link text
            $hyperlink = New-Object Windows.Documents.Hyperlink
            $hyperlink.Inlines.Add($parts[$i])
            $hyperlink.NavigateUri = $parts[$i + 1]
            $hyperlink.Foreground = "#0078D7"
            $hyperlink.TextDecorations = $null
            $hyperlink.Add_Click({
                    param($sender, $e)
                    Start-Process $sender.NavigateUri
                    $e.Handled = $true
                })
            $inlines.Add($hyperlink)
        }
    }
    
    $descText.Inlines.AddRange($inlines)
    $grid.Children.Add($descText)
    
    $border.Child = $grid
    
    return @{
        Border   = $border
        CheckBox = $checkbox
        Category = $Category
    }
}

# Function to create a tweak item
function New-TweakItem {
    param (
        [string]$Name,
        [string]$Description,
        [string]$FilePath,
        [string]$FileType
    )
    
    $border = New-Object System.Windows.Controls.Border
    $border.Style = $window.FindResource("AppItemStyle")
    $border.Margin = "5"
    $border.MinWidth = 200
    $border.MaxWidth = 300
    $border.Height = 120
    
    $grid = New-Object System.Windows.Controls.Grid
    $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height = "Auto" }))
    $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height = "*" }))
    
    $topPanel = New-Object System.Windows.Controls.StackPanel
    $topPanel.Orientation = "Horizontal"
    $topPanel.Margin = "0,0,0,5"
    
    $toggle = New-Object System.Windows.Controls.Primitives.ToggleButton
    $toggle.Style = $window.FindResource("ToggleSwitchStyle")
    $toggle.Margin = "0,0,10,0"
    $toggle.VerticalAlignment = "Center"
    
    $nameText = New-Object System.Windows.Controls.TextBlock
    $nameText.Text = $Name
    $nameText.FontWeight = "SemiBold"
    $nameText.VerticalAlignment = "Center"
    $nameText.TextWrapping = "Wrap"
    
    $topPanel.Children.Add($toggle)
    $topPanel.Children.Add($nameText)
    
    $grid.Children.Add($topPanel)
    
    $descText = New-Object System.Windows.Controls.TextBlock
    $descText.Text = $Description
    $descText.TextWrapping = "Wrap"
    $descText.Foreground = "#AAAAAA"
    $descText.MaxHeight = 60
    $descText.TextTrimming = "CharacterEllipsis"
    $descText.SetValue([System.Windows.Controls.Grid]::RowProperty, 1)
    
    $grid.Children.Add($descText)
    $border.Child = $grid
    
    return @{
        Border   = $border
        Toggle   = $toggle
        FilePath = $FilePath
        FileType = $FileType
    }
}

# Function to execute a tweak file
function Invoke-TweakFile {
    param (
        [string]$FilePath,
        [string]$FileType,
        [System.Windows.Controls.TextBox]$LogBox
    )
    
    try {
        switch ($FileType.ToLower()) {
            "reg" {
                $LogBox.AppendText("Applying registry file: $FilePath`r`n")
                # Create a temporary file to store the reg file content
                $tempFile = [System.IO.Path]::GetTempFileName()
                Copy-Item $FilePath $tempFile
                
                # Import the registry file
                $process = Start-Process "reg" -ArgumentList "import `"$tempFile`"" -NoNewWindow -Wait -PassThru
                
                # Clean up
                Remove-Item $tempFile -Force
                
                if ($process.ExitCode -eq 0) {
                    $LogBox.AppendText("Registry file applied successfully`r`n")
                }
                else {
                    throw "Registry import failed with exit code: $($process.ExitCode)"
                }
            }
            "ps1" {
                $LogBox.AppendText("Executing PowerShell script: $FilePath`r`n")
                # Execute the PowerShell script with elevated privileges
                $process = Start-Process "powershell" -ArgumentList "-ExecutionPolicy Bypass -File `"$FilePath`"" -NoNewWindow -Wait -PassThru
                
                if ($process.ExitCode -eq 0) {
                    $LogBox.AppendText("PowerShell script executed successfully`r`n")
                }
                else {
                    throw "PowerShell script failed with exit code: $($process.ExitCode)"
                }
            }
            default {
                throw "Unsupported file type: $FileType"
            }
        }
    }
    catch {
        $LogBox.AppendText("Error: $_`r`n")
        throw
    }
}

# Create expandable categories for apps
$categories = @{}
foreach ($category in $appsConfig.categories) {
    $categories[$category] = New-Object System.Collections.ArrayList
    foreach ($package in $appsConfig.packages | Where-Object { $_.category -eq $category }) {
        $appItem = New-AppItem -Name $package.name -Description $package.description -PackageIdentifier $package.packageIdentifier -Category $category
        $categories[$category].Add($appItem)
        $checkboxes[$package.packageIdentifier] = $appItem.CheckBox
    }
}

# Create expandable categories
foreach ($category in $categories.Keys | Sort-Object) {
    $expander = New-Object System.Windows.Controls.Expander
    $expander.Header = $category
    $expander.IsExpanded = $false
    $expander.Margin = "0,5,0,5"
    $expander.Background = "#252526"
    $expander.BorderBrush = "#3a3a3a"
    $expander.BorderThickness = "1"
    
    $wrapPanel = New-Object System.Windows.Controls.WrapPanel
    $wrapPanel.Margin = "10,5,5,5"
    $wrapPanel.ItemWidth = 250
    $wrapPanel.ItemHeight = 130
    
    foreach ($appItem in $categories[$category]) {
        $wrapPanel.Children.Add($appItem.Border)
    }
    
    $border = New-Object System.Windows.Controls.Border
    $border.Background = "#252526"
    $border.BorderBrush = "#3a3a3a"
    $border.BorderThickness = "1"
    $border.Padding = "10"
    $border.Child = $wrapPanel
    
    $expander.Content = $border
    $programList.Children.Add($expander)
}

# Select All button click handler
$selectAllBtn.Add_Click({
        foreach ($checkbox in $checkboxes.Values) {
            if ($checkbox -ne $null) {
                $checkbox.IsChecked = $true
            }
        }
    })

# Uncheck All button click handler
$uncheckAllBtn.Add_Click({
        foreach ($checkbox in $checkboxes.Values) {
            if ($checkbox -ne $null) {
                $checkbox.IsChecked = $false
            }
        }
    })

# Select All button click handler for Tweaks
$selectAllFavBtn.Add_Click({
        foreach ($checkbox in $tweakCheckboxes.Values) {
            $checkbox.IsChecked = $true
        }
    })

# Uncheck All button click handler for Tweaks
$uncheckAllFavBtn.Add_Click({
        foreach ($checkbox in $tweakCheckboxes.Values) {
            $checkbox.IsChecked = $false
        }
    })

# Select All button click handler for Repair
$selectAllRepairBtn.Add_Click({
        foreach ($checkbox in $repairCheckboxes.Values) {
            $checkbox.IsChecked = $true
        }
    })

# Uncheck All button click handler for Repair
$uncheckAllRepairBtn.Add_Click({
        foreach ($checkbox in $repairCheckboxes.Values) {
            $checkbox.IsChecked = $false
        }
    })

# Add tweaks to the UI
foreach ($category in $tweakCategories.Keys | Sort-Object) {
    $categoryTitle = New-Object System.Windows.Controls.TextBlock
    $categoryTitle.Text = $category
    $categoryTitle.FontSize = 16
    $categoryTitle.FontWeight = "Bold"
    $categoryTitle.Margin = "0,10,0,5"
    $favoritesList.Children.Add($categoryTitle)
    
    $wrapPanel = New-Object System.Windows.Controls.WrapPanel
    $wrapPanel.Margin = "10,5,5,5"
    $wrapPanel.ItemWidth = 250
    $wrapPanel.ItemHeight = 130
    
    foreach ($tweak in $tweakCategories[$category]) {
        $tweakItem = New-TweakItem -Name $tweak.name -Description $tweak.description -FilePath $tweak.filePath -FileType $tweak.fileType
        $wrapPanel.Children.Add($tweakItem.Border)
        $tweakCheckboxes[$tweak.filePath] = $tweakItem.Toggle
    }
    
    $favoritesList.Children.Add($wrapPanel)
}

# Add repair items to the UI
foreach ($category in $tweakCategories.Keys | Sort-Object) {
    $categoryTitle = New-Object System.Windows.Controls.TextBlock
    $categoryTitle.Text = $category
    $categoryTitle.FontSize = 16
    $categoryTitle.FontWeight = "Bold"
    $categoryTitle.Margin = "0,10,0,5"
    $repairList.Children.Add($categoryTitle)
    
    $wrapPanel = New-Object System.Windows.Controls.WrapPanel
    $wrapPanel.Margin = "10,5,5,5"
    $wrapPanel.ItemWidth = 250
    $wrapPanel.ItemHeight = 130
    
    foreach ($tweak in $tweakCategories[$category]) {
        $tweakItem = New-TweakItem -Name $tweak.name -Description $tweak.description -FilePath $tweak.filePath -FileType $tweak.fileType
        $wrapPanel.Children.Add($tweakItem.Border)
        $repairCheckboxes[$tweak.filePath] = $tweakItem.Toggle
    }
    
    $repairList.Children.Add($wrapPanel)
}

# Button click: install selected tweaks
$installTweaksBtn.Add_Click({
        $logBoxTweaks.Text = "Starting tweak installation...`r`n"
        $progressBarTweaks.Value = 0
        $totalTweaks = ($tweakCheckboxes.Values | Where-Object { $_.IsChecked }).Count
        $currentTweak = 0

        foreach ($tweak in $tweaks) {
            $toggle = $tweakCheckboxes[$tweak.filePath]
            if ($toggle.IsChecked) {
                $currentTweak++
                $progress = ($currentTweak / $totalTweaks) * 100
                $progressBarTweaks.Value = $progress
                
                try {
                    Invoke-TweakFile -FilePath $tweak.filePath -FileType $tweak.fileType -LogBox $logBoxTweaks
                }
                catch {
                    $logBoxTweaks.AppendText("Failed to apply tweak: $($tweak.name)`r`n")
                    [System.Windows.MessageBox]::Show("Error applying tweak: $($tweak.name)`n$_", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
                }
            }
        }
        $logBoxTweaks.AppendText("Tweak installation complete!`r`n")
        [System.Windows.MessageBox]::Show("Tweak installation complete!")
    })

# Button click: install selected programs via winget
$installBtn.Add_Click({
        $logBox.Text = "Starting application installation...`r`n"
        $progressBar.Value = 0
        $totalApps = ($checkboxes.Values | Where-Object { $_.IsChecked }).Count
        $currentApp = 0

        foreach ($program in $appsConfig.packages) {
            $cb = $checkboxes[$program.packageIdentifier]
            if ($cb.IsChecked) {
                $currentApp++
                $progress = ($currentApp / $totalApps) * 100
                $progressBar.Value = $progress
                $logBox.AppendText("Installing: $($program.name)`r`n")
                Start-Process "winget" -ArgumentList "install --id $($program.packageIdentifier) -e --accept-source-agreements --accept-package-agreements" -NoNewWindow -Wait
            }
        }
        $logBox.AppendText("Installation complete!`r`n")
        [System.Windows.MessageBox]::Show("Installation complete!")
    })

# Button click: run selected repairs
$installRepairBtn.Add_Click({
        $logBoxRepair.Text = "Starting repair operations...`r`n"
        $progressBarRepair.Value = 0
        $totalRepairs = ($repairCheckboxes.Values | Where-Object { $_.IsChecked }).Count
        $currentRepair = 0

        foreach ($tweak in $tweaks) {
            $toggle = $repairCheckboxes[$tweak.filePath]
            if ($toggle.IsChecked) {
                $currentRepair++
                $progress = ($currentRepair / $totalRepairs) * 100
                $progressBarRepair.Value = $progress
                
                try {
                    Invoke-TweakFile -FilePath $tweak.filePath -FileType $tweak.fileType -LogBox $logBoxRepair
                }
                catch {
                    $logBoxRepair.AppendText("Failed to run repair: $($tweak.name)`r`n")
                    [System.Windows.MessageBox]::Show("Error running repair: $($tweak.name)`n$_", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
                }
            }
        }
        $logBoxRepair.AppendText("Repair operations complete!`r`n")
        [System.Windows.MessageBox]::Show("Repair operations complete!")
    })

# Run GUI
$window.ShowDialog()
