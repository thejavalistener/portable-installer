#Set-StrictMode -Version Latest

$endl = "`n"

# function cMenu($options,$indent=3,$defaultIndex = 0,$timeoutSeconds = -1)
# {
#     if($NULL -eq $options -or $options.Count -eq 0)
#     {
#         return -1
#     }

#     $oldCursorVisible = [Console]::CursorVisible
#     [Console]::CursorVisible = $false

#     try
#     {
#         $index = $defaultIndex
#         $maxLen = ($options | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum

#         # reservar espacio para menu + timer
#         #for($i = 0; $i -lt ($options.Count + 1); $i++)
#         for($i = 0; $i -lt $options.Count; $i++)
#         {
#             Write-Host ""
#         }

#         #$top = [Console]::CursorTop - ($options.Count + 1)
#         $top = [Console]::CursorTop - $options.Count
#         $startTime = Get-Date

#         while($true)
#         {
#             for($i = 0; $i -lt $options.Count; $i++)
#             {
#                 [Console]::SetCursorPosition(0, $top + $i)

#                 $text = $options[$i].PadRight($maxLen)

#                 if($i -eq $index)
#                 {
#                      $extra = ""

#                     if($timeoutSeconds -ge 0)
#                     {
#                         $extra = " ($remaining)"
#                     }

#                     $line = (" " * $indent)+">[$text]$extra"
#                 }
#                 else
#                 {
#                     $line = (" " * $indent)+"  $text "
#                 }

#                 Write-Host ($line.PadRight([Console]::WindowWidth - 1)) -NoNewline
#             }

#             # [Console]::SetCursorPosition(0, $top + $options.Count)

#             # if($timeoutSeconds -ge 0)
#             # {
#             #     $elapsed = ((Get-Date) - $startTime).TotalSeconds
#             #     $remaining = [Math]::Ceiling($timeoutSeconds - $elapsed)

#             #     if($remaining -lt 0)
#             #     {
#             #         $remaining = 0
#             #     }

#             #     $linex = (" " * ($($indent)+2))
#             #     $timerLine = "$($linex)Seleccion automatica en $remaining segundos..."
#             #     Write-Host ($timerLine.PadRight([Console]::WindowWidth - 1)) -ForegroundColor DarkGray -NoNewline

#             #     if($elapsed -ge $timeoutSeconds)
#             #     {
#             #         # [Console]::SetCursorPosition(0, $top + $options.Count + 1)
#             #         # Write-Host ""
#             #         #return $index

#             #         [Console]::SetCursorPosition(0, $top + $options.Count)
#             #         Write-Host "`r$(' ' * ([Console]::WindowWidth - 1))" -NoNewline
#             #         return $index
#             #     }
#             # }

#             Start-Sleep -Milliseconds 100

#             if([Console]::KeyAvailable)
#             {
#                 $key = [Console]::ReadKey($true)

#                 switch($key.Key)
#                 {
#                     "UpArrow"
#                     {
#                         if($index -gt 0)
#                         {
#                             $index--
#                         }
#                     }

#                     "DownArrow"
#                     {
#                         if($index -lt ($options.Count - 1))
#                         {
#                             $index++
#                         }
#                     }

#                     #"Enter"
#                     #{
#                     #    [Console]::SetCursorPosition(0, $top + $options.Count + 1)
#                     #    #Write-Host " PEPINO"
#                     #    return $index
#                     #}
#                     "Enter"
#                     {
#                         # Calculamos la posición donde termina el menú
#                         $finalPos = $top + $options.Count
                        
#                         # Subimos el cursor un lugar antes de salir
#                         [Console]::SetCursorPosition(0, $finalPos)
                        
#                         return $index
#                     }
#                 }
#             }
#         }
#     }
#     finally
#     {
#         [Console]::CursorVisible = $oldCursorVisible
#     }
# }

function cMenu($options,$indent=3,$defaultIndex = 0,$timeoutSeconds = -1)
{
    if($NULL -eq $options -or $options.Count -eq 0)
    {
        return -1
    }

    $oldCursorVisible = [Console]::CursorVisible
    [Console]::CursorVisible = $false

    try
    {
        $index = $defaultIndex
        $maxLen = ($options | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum

        for($i = 0; $i -lt $options.Count; $i++)
        {
            Write-Host ""
        }

        $top = [Console]::CursorTop - $options.Count
        $startTime = Get-Date

        while($true)
        {
            $remaining = 0

            if($timeoutSeconds -ge 0)
            {
                $elapsed = ((Get-Date) - $startTime).TotalSeconds
                $remaining = [Math]::Ceiling($timeoutSeconds - $elapsed)

                if($remaining -lt 0)
                {
                    $remaining = 0
                }

                if($elapsed -ge $timeoutSeconds)
                {
                    [Console]::SetCursorPosition(0, $top + $options.Count)
                    return $index
                }
            }

            for($i = 0; $i -lt $options.Count; $i++)
            {
                [Console]::SetCursorPosition(0, $top + $i)

                $text = $options[$i].PadRight($maxLen)

                if($i -eq $index)
                {
                    $extra = ""

                    if($timeoutSeconds -ge 0)
                    {
                        $extra = " ($remaining)"
                    }

                    $line = (" " * $indent) + ">[$text]$extra"
                }
                else
                {
                    $line = (" " * $indent) + "  $text "
                }

                Write-Host ($line.PadRight([Console]::WindowWidth - 1)) -NoNewline
            }

            Start-Sleep -Milliseconds 100

            if([Console]::KeyAvailable)
            {
                $key = [Console]::ReadKey($true)

                switch($key.Key)
                {
                    "UpArrow"
                    {
                        if($index -gt 0)
                        {
                            $index--
                        }
                    }

                    "DownArrow"
                    {
                        if($index -lt ($options.Count - 1))
                        {
                            $index++
                        }
                    }

                    "Enter"
                    {
                        [Console]::SetCursorPosition(0, $top + $options.Count)
                        return $index
                    }
                }
            }
        }
    }
    finally
    {
        [Console]::CursorVisible = $oldCursorVisible
    }
}

function cBlink($message, $durationInMillis, $color = "white", $attr = "regular")
{
    $end = (Get-Date).AddMilliseconds($durationInMillis)

    while ((Get-Date) -lt $end)
    {
        Write-Host "`r$message" -ForegroundColor $color -NoNewline
        Start-Sleep -Milliseconds 400

        Write-Host "`r$(' ' * $message.Length)`r" -NoNewline
        Start-Sleep -Milliseconds 300
    }

#    Write-Host "`r$(' ' * $message.Length)`r" -NoNewline

    Write-Host "`r$message" -ForegroundColor $color
}

function cPause($millis=500)
{
    Start-Sleep -Milliseconds $millis    
}

#function cStep($mssg,$delay=1000)
#{
#    Write-Host `n$mssg -ForegroundColor Cyan
#    cPause $delay
#}

function cStep($mssg,$delay=1000)
{
    if ($null -eq $script:cStepNumber)
    {
        $script:cStepNumber = 0
    }

    $script:cStepNumber++

    [Console]::WriteLine()
    Write-Host "[$script:cStepNumber] $mssg" -ForegroundColor Cyan
    cPause $delay
}


function cAsk($mssg,$delay=500)
{
    Write-Host $mssg -ForegroundColor Magenta
    cPause $delay
}

function cError($mssg,$delay=1000)
{
    Write-Host $mssg -ForegroundColor Red
    cPause $delay
}

function cWarn($mssg,$delay=500)
{
    Write-Host $mssg -ForegroundColor Yellow
    cPause $delay
}

function cInfo($mssg,$delay=500)
{
    Write-Host $mssg -ForegroundColor Green
    cPause $delay
}
    
function cOut($mssg,$delay=500)
{
    Write-Host $mssg 
    cPause $delay
}

function pressAnyKey($prefix="")
{
    cOut "${prefix}Presione una tecla para continuar..." 
    [void][System.Console]::ReadKey($true)
}

function arrayToString($array)
{
    $ret = ""

    for( $i = 0; $i -lt $array.Length; $i++ )
    {
        if( $i -gt 0 )
        {
            $ret += ", "
        }

        $ret += $array[$i]
    }

    return $ret
}

Export-ModuleMember -Function * -Variable *