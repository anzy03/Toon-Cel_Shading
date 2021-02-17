using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GirlController : MonoBehaviour
{
    [SerializeField]
    private float _moveSpeed;


    private void Update()
    {
        transform.Rotate(Vector3.up * _moveSpeed, Space.Self);
    }




}
