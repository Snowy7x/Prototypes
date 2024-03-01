using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Playables;
using Core.Attributes;

public class TimelineManager : MonoBehaviour
{
    [SerializeField] private PlayableDirector[] playableDirectors;
    
    public void PlayTimeline(int index)
    {
        playableDirectors[index].Play();
    }
    
    public void StopTimeline(int index)
    {
        playableDirectors[index].Stop();
    }
    
    public void PauseTimeline(int index)
    {
        playableDirectors[index].Pause();
    }
    
    public void ResumeTimeline(int index)
    {
        playableDirectors[index].Resume();
    }
    
    [Button("Play All Timelines")]
    public void PlayAllTimelines()
    {
        StopAllTimelines();
        foreach (PlayableDirector playableDirector in playableDirectors)
        {
            playableDirector.Play();
        }
    }
    
    [Button("Stop All Timelines")]
    public void StopAllTimelines()
    {
        foreach (PlayableDirector playableDirector in playableDirectors)
        {
            playableDirector.Stop();
        }
    }
}
