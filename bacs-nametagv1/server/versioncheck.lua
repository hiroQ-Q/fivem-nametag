AddEventHandler('onResourceStarting', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
      return
    end
    
    print('----------------------------------')
    print()
    print(resourceName..' resource started!')
    print()
    print('----------------------------------')
  end)