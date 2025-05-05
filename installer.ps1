Add-Type -AssemblyName PresentationFramework

# Load JSON
$apps = Get-Content -Raw -Path ".\apps.json" | ConvertFrom-Json #!important !fetch config from local files for testing purpose.
# $appsUrl = "https://raw.githubusercontent.com/devo-tion/pget-pw/refs/heads/main/apps.json"
# $apps = Invoke-RestMethod -Uri $appsUrl

# Define static XAML with a placeholder StackPanel
$xaml = @"
<Window 
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="App Installer" WindowState="Maximized" ResizeMode="NoResize"
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
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TabControl Grid.Row="0">
            <TabItem Header="Applications">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>

                    <StackPanel Grid.Row="0" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,0,0,10">
                        <Button Name="selectAllBtn" Content="Select All" Margin="0,0,5,0"/>
                        <Button Name="uncheckAllBtn" Content="Uncheck All" Margin="0,0,5,0"/>
                    </StackPanel>

                    <ScrollViewer Grid.Row="1">
                        <StackPanel Name="programList" Margin="5"/>
                    </ScrollViewer>
                </Grid>
            </TabItem>

            <TabItem Header="Tweaks">
                <DockPanel>
                    <StackPanel DockPanel.Dock="Top" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,0,0,10">
                        <Button Name="selectAllFavBtn" Content="Select All" Margin="0,0,5,0"/>
                        <Button Name="uncheckAllFavBtn" Content="Uncheck All" Margin="0,0,5,0"/>
                    </StackPanel>
                    <ScrollViewer>
                        <StackPanel Name="favoritesList"/>
                    </ScrollViewer>
                </DockPanel>
            </TabItem>

            <TabItem Header="About">
                <StackPanel>
                    <TextBlock Text="Pget-pw is a PowerShell script that installs applications using winget."/>
                    <TextBlock Text="Version 0.1"/>
                    <TextBlock Text="Author: devo-tion"/>
                </StackPanel>
            </TabItem>
        </TabControl>

        <StackPanel Grid.Row="1">
            <ProgressBar Name="progressBar" Margin="0,10,0,10" Minimum="0" Maximum="100"/>
            <Button Name="installBtn" Content="Install Selected"/>
            <TextBox Name="logBox" Height="100" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto"/>
        </StackPanel>
    </Grid>
</Window>
"@

# Parse XAML into Window object
[xml]$xamlXml = $xaml
$reader = New-Object System.Xml.XmlNodeReader $xamlXml
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get elements
$programList = $window.FindName("programList")
$installBtn = $window.FindName("installBtn")
$selectAllBtn = $window.FindName("selectAllBtn")
$uncheckAllBtn = $window.FindName("uncheckAllBtn")

# Store checkboxes for later reference
$checkboxes = @{}

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

# Dynamically add application items
$categories = @{}
foreach ($program in $apps) {
    $appItem = New-AppItem -Name $program.Name -Description $program.Description -PackageIdentifier $program.PackageIdentifier -Category $program.Category
    if (-not $categories.ContainsKey($program.Category)) {
        $categories[$program.Category] = New-Object System.Collections.ArrayList
    }
    $categories[$program.Category].Add($appItem)
    $checkboxes[$program.PackageIdentifier] = $appItem.CheckBox
}

# Create expandable categories
foreach ($category in $categories.Keys | Sort-Object) {
    $expander = New-Object System.Windows.Controls.Expander
    $expander.Header = $category
    $expander.IsExpanded = $true
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
            $checkbox.IsChecked = $true
        }
    })

# Uncheck All button click handler
$uncheckAllBtn.Add_Click({
        foreach ($checkbox in $checkboxes.Values) {
            $checkbox.IsChecked = $false
        }
    })

# Button click: install selected programs via winget
$installBtn.Add_Click({
        foreach ($program in $apps) {
            $cb = $checkboxes[$program.PackageIdentifier]
            if ($cb.IsChecked) {
                Start-Process "winget" -ArgumentList "install --id $($program.PackageIdentifier) -e --accept-source-agreements --accept-package-agreements" -NoNewWindow -Wait
            }
        }
        [System.Windows.MessageBox]::Show("Installation complete!")
    })

# Run GUI
$window.ShowDialog()
