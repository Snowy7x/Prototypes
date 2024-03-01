using System.Collections;
using System.Collections.Generic;
using Core.Attributes;
using UnityEngine;

public class DissolveObject : MonoBehaviour
{
    [SerializeField] private float speed = 1.0f;
    [SerializeField] private float noiseStrength = 0.25f;
    [SerializeField] private float objectHeight = 1.0f;
    [SerializeField] private ParticleSystem ps;

    private Material material;

    private bool playing = false;
    private float time;

    private void Awake()
    {
        material = GetComponent<Renderer>().material;
    }

    private void Update()
    {
        if (!playing) return;
        time += Time.deltaTime * speed;
        SetHeight(Mathf.Lerp(objectHeight, 0.0f, time));
        
        if (time >= 0.7) ps.Stop();
        
        if (time >= 1.0f) playing = false;
        
    }

    [Button("Dissolve Object")]
    private void Run()
    {
        time = 0f;
        playing = true;
        ps.Play();
    }

    private void SetHeight(float height)
    {
        material.SetFloat("_CutoffHeight", height);
        material.SetFloat("_NoiseStrength", noiseStrength);
    }
}
