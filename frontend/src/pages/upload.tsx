import React, { useState } from 'react'
import type { ChangeEvent } from 'react'
const { Web3Storage } = require('web3.storage')
const API_TOKEN =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJkaWQ6ZXRocjoweDc2MTJlNmJhMURhNTNDNTYyY2JlNkM0RUEwNzNEZEU2MERCYUZmQkYiLCJpc3MiOiJ3ZWIzLXN0b3JhZ2UiLCJpYXQiOjE2NzY2MDczMTMzMjIsIm5hbWUiOiJTQlQifQ.TNuSAaWuHEk-F0JZt34siyGlPUTYj7cOkZiwVbiZI0Y'
const client = new Web3Storage({ token: API_TOKEN })

export default function upload() {
  const [img, setImg] = useState('')
  const uploadIPFS = async (e: ChangeEvent<HTMLInputElement>) => {
    if (e.target.files?.length === 1) {
      const file = e.target.files
      const rootCid = await client.put(file)
      const res = await client.get(rootCid)
      const files = await res.files()
      for (const file of files) {
        setImg('https://dweb.link/ipfs/' + file.cid)
      }
    }
  }
  return (
    <div className="container">
      <div className="w-2/3 m-auto flex justify-center shadow-xl py-10 flex-col items-center">
        <input
          type="file"
          accept="image/*"
          className="file-input file-input-bordered file-input-info w-full max-w-xs"
          onChange={uploadIPFS}
        />
        <img src={img} alt="" className="mt-5" />
      </div>
    </div>
  )
}
