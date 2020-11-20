using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class StartButton : MonoBehaviour
{
    public Button playButton;
    // Start is called before the first frame update
    void Start()
    {
        playButton.onClick.AddListener(TaskOnClick);
    }

    // Update is called once per frame
    
    void TaskOnClick()
    {
        //Output this to console when Button1 or Button3 is clicked
        Debug.Log("You have clicked the button!");
        Debug.Log("Change Scene");
    }
    
    
    
    
    /*void Update()
    {
        
    }*/
}
