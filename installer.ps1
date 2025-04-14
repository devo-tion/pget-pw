Add-Type -AssemblyName PresentationFramework

# Load JSON
# $programs = Get-Content -Raw -Path ".\programs.json" | ConvertFrom-Json
$apps = Get-Content -Raw -Path ".\apps.json" | ConvertFrom-Json

# Define static XAML with a placeholder StackPanel
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="App Installer" Height="600" Width="500"
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
    </Window.Resources>

    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height='Auto'/>    <!-- Select All/Uncheck All Buttons -->
            <RowDefinition Height='3*'/>     <!-- Program List -->
            <RowDefinition Height='Auto'/>   <!-- Progress Bar -->
            <RowDefinition Height='Auto'/>   <!-- Install Button -->
            <RowDefinition Height='*'/>      <!-- Log Box -->
        </Grid.RowDefinitions>

        <Grid Grid.Row='0'>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <StackPanel Grid.Column="0" Orientation="Horizontal" HorizontalAlignment="Right">
                <Button Name="selectAllBtn" Content="Select All" Margin="0,0,5,0"/>
                <Button Name="uncheckAllBtn" Content="Uncheck All" Margin="0,0,5,0"/>
            </StackPanel>
        </Grid>

        <ScrollViewer Grid.Row='1'>
            <StackPanel Name="programList"/>
        </ScrollViewer>

        <ProgressBar Name="progressBar" Grid.Row='2' Margin="0,10,0,10" Minimum="0" Maximum="100"/>

        <Button Name="installBtn" Grid.Row='3' Content="Install Selected"/>

        <TextBox Name="logBox" Grid.Row='4' Height="100" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto"/>
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

# Dynamically add checkboxes
foreach ($program in $apps) {
    $checkbox = New-Object Windows.Controls.CheckBox
    $checkbox.Content = $program.PackageIdentifier
    $checkbox.Margin = "5"
    $programList.Children.Add($checkbox)
    $checkboxes[$program.PackageIdentifier] = $checkbox
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
